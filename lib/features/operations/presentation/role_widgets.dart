import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/app_card.dart';
import '../data/operations_repository.dart';

/// Poll only while this tab/route is visible and the application is foregrounded.
class LiveResource<T> extends StatefulWidget {
  const LiveResource({
    super.key,
    required this.load,
    required this.builder,
    this.resourceKey,
    this.poll = true,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function()) builder;
  final Object? resourceKey;
  final bool poll;

  // Update this resource only after an API mutation succeeds;
  // ignore older polls.
  static void commit<T>(BuildContext context, T Function(T current) update) {
    context.findAncestorStateOfType<_LiveResourceState<T>>()?.commit(update);
  }

  @override
  State<LiveResource<T>> createState() => _LiveResourceState<T>();
}

class _LiveResourceState<T> extends State<LiveResource<T>>
    with WidgetsBindingObserver {
  T? data;
  Object? error;

  bool loading = false;
  bool active = false;
  bool foreground = true;

  Timer? timer;
  int revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tickerMode = TickerMode.valuesOf(context);

    final visible =
        tickerMode.enabled && (ModalRoute.isCurrentOf(context) ?? true);

    if (visible != active) {
      active = visible;

      if (active && foreground) {
        reload();
      } else {
        timer?.cancel();
      }
    }
  }

  @override
  void didUpdateWidget(covariant LiveResource<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resourceKey != widget.resourceKey) {
      revision++;
      loading = false;
      data = null;
      error = null;
      reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;

    timer?.cancel();

    if (foreground && active) {
      reload();
    }
  }

  void commit(T Function(T current) update) {
    if (!mounted || data == null) {
      return;
    }

    timer?.cancel();

    setState(() {
      revision++;
      loading = false;
      data = update(data as T);
      error = null;
    });
  }

  Future<void> reload() async {
    if (!mounted || loading || !active || !foreground) {
      return;
    }

    timer?.cancel();

    final generation = revision;

    setState(() {
      loading = true;
    });

    try {
      final result = await widget.load();

      if (mounted && generation == revision) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (failure) {
      if (mounted && generation == revision) {
        setState(() {
          error = failure;
        });
      }
    } finally {
      if (mounted && generation == revision) {
        setState(() {
          loading = false;
        });

        if (widget.poll && active && foreground) {
          timer = Timer(const Duration(seconds: 7), reload);
        }
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return error == null
          ? const AppLoading()
          : AppError(message: error.toString(), onRetry: reload);
    }

    return Column(
      children: [
        if (error != null)
          MaterialBanner(
            content: Text('Refresh failed: $error. Showing last loaded data.'),
            actions: [
              TextButton(onPressed: reload, child: const Text('Retry')),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: reload,
            child: Builder(
              builder: (context) => widget.builder(context, data as T, reload),
            ),
          ),
        ),
      ],
    );
  }
}

class RoleAction extends StatefulWidget {
  const RoleAction({
    super.key,
    required this.title,
    required this.action,
    this.confirm,
    this.icon = Icons.check,
  });

  final String title;
  final Future<void> Function() action;
  final String? confirm;
  final IconData icon;

  @override
  State<RoleAction> createState() => _RoleActionState();
}

class _RoleActionState extends State<RoleAction> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(widget.icon, size: 18),
      label: Text(busy ? 'Saving…' : widget.title),
      onPressed: busy
          ? null
          : () async {
              setState(() {
                busy = true;
              });

              try {
                if (widget.confirm != null &&
                    !await confirmAction(
                      context,
                      widget.title,
                      widget.confirm!,
                    )) {
                  return;
                }

                if (!mounted) {
                  return;
                }

                await widget.action();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              } finally {
                if (mounted) {
                  setState(() {
                    busy = false;
                  });
                }
              }
            },
    );
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final failed = [
      'failed',
      'rejected',
      'declined',
      'cancelled',
      'suspended',
      'delivery_failed',
    ].contains(status);

    return Chip(
      backgroundColor: failed
          ? scheme.errorContainer
          : scheme.secondaryContainer,
      label: Text(
        label(status),
        style: TextStyle(
          color: failed ? scheme.onErrorContainer : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

Widget metrics(BuildContext context, Map<String, dynamic> data) {
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: data.entries
        .map(
          (entry) => SizedBox(
            width: 150,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key),
                  const SizedBox(height: 8),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

Widget roleList(List<Widget> children) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: children,
  );
}

Widget title(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
  );
}

void openPage(BuildContext context, String heading, Widget body) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(heading)),
        body: body,
      ),
    ),
  );
}
