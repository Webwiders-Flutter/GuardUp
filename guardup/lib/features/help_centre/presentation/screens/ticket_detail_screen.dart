import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/services/media_picker_service.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_image_viewer.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/help_centre/domain/entities/ticket_entity.dart';
import 'package:guardup/features/help_centre/domain/repositories/support_repository.dart';

import 'package:guardup/core/utils/image_picker_dialog.dart';

import '../../../../core/widgets/common/uploaded_file_item_widget.dart';
import '../bloc/support_cubit.dart';
import '../bloc/support_state.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketEntity ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyController = TextEditingController();
  final ValueNotifier<List<File>> _selectedFiles = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();
  List<TicketReplyEntity> _cachedReplies = [];
  late TicketEntity _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
  }

  @override
  void didUpdateWidget(covariant TicketDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket != widget.ticket) {
      _currentTicket = widget.ticket;
    }
  }

  void _popWithUpdatedTicket() {
    if (mounted) {
      Navigator.of(context).pop(_currentTicket);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _selectedFiles.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh(BuildContext cubitContext) async {
    final result = await sl<SupportRepository>().getTicketById(
      widget.ticket.id,
    );
    result.fold((_) => null, (updatedTicket) {
      if (mounted) {
        setState(() {
          _currentTicket = updatedTicket;
        });
      }
    });
    await cubitContext.read<SupportCubit>().getTicketReplies(
      widget.ticket.id,
      showLoading: false,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    final file = await showPickFileDialog(context, sl<MediaPickerService>());
    if (file != null) {
      _selectedFiles.value = [..._selectedFiles.value, file];
    }
  }

  void _sendReply(BuildContext cubitContext) {
    if (_currentTicket.status == TicketStatus.closed) return;
    if (_replyController.text.trim().isEmpty && _selectedFiles.value.isEmpty) {
      return;
    }
    cubitContext.read<SupportCubit>().addReply(
      ticketId: widget.ticket.id,
      message: _replyController.text.trim(),
      attachments: _selectedFiles.value,
    );
    _replyController.clear();
    _selectedFiles.value = [];
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return Colors.orange;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.closed:
        return Colors.green;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return context.l10n.pending;
      case TicketStatus.inProgress:
        return context.l10n.inProgress;
      case TicketStatus.closed:
        return context.l10n.closed;
    }
  }

  void _openImageGalleryLightbox(List<String> urls, int initialIndex) {
    if (urls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomImageViewer.gallery(
          imageUrls: urls,
          initialIndex: initialIndex,
          heroTag: 'ticket_image_${urls[initialIndex]}',
        ),
      ),
    );
  }

  Widget _buildStackedImages(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    const double imageSize = 52.0;
    const double offset = 18.0;
    const int maxVisible = 3;
    final int visibleCount = urls.length > maxVisible
        ? maxVisible
        : urls.length;
    final int remainingCount = urls.length - maxVisible;
    final double containerWidth = imageSize + (visibleCount - 1) * offset;

    return GestureDetector(
      onTap: () => _openImageGalleryLightbox(urls, 0),
      child: SizedBox(
        width: containerWidth,
        height: imageSize,
        child: Stack(
          children: List.generate(visibleCount, (index) {
            final isLastVisible = index == maxVisible - 1;
            final showMoreBadge = isLastVisible && remainingCount > 0;

            return Positioned(
              left: index * offset,
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.lightBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(imageUrl: urls[index], fit: BoxFit.cover),
                      if (showMoreBadge)
                        Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SupportCubit>()
        ..getTicketReplies(widget.ticket.id)
        ..subscribeToReplies(
          widget.ticket.id,
          onTicketUpdated: (updatedTicket) {
            if (mounted) {
              setState(() {
                _currentTicket = updatedTicket;
              });
            }
          },
        ),
      child: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            UIFeedback.showSnackbar(context, state.message, isError: true);
            // If the server says ticket is closed, refresh the ticket data
            // so the UI updates to show the closed status and disables input.
            if (state.message.toLowerCase().contains('closed')) {
              _onRefresh(context);
            }
          } else if (state is TicketRepliesLoaded) {
            _cachedReplies = state.replies;
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _popWithUpdatedTicket();
            },
            child: Scaffold(
              backgroundColor: AppColors.mainBackgroundColor,
              appBar: CustomAppBar(
                title: "#${_currentTicket.id.substring(0, 8).toUpperCase()}",
                showBackButton: true,
                onBackPressed: _popWithUpdatedTicket,
              ),
              body: Column(
                children: [
                  // Header Ticket Info Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.lightBackgroundColor,
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_currentTicket.attachmentUrls.isNotEmpty) ...[
                              _buildStackedImages(
                                _currentTicket.attachmentUrls,
                              ),
                              12.width,
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Row(
                                    mainAxisAlignment: .spaceBetween,
                                    children: [
                                      Flexible(
                                        child: AppText(
                                          _currentTicket.subject,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          // maxLines: 2,
                                          // overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: AppText(
                                          _currentTicket.category.toUpperCase(),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppText(
                                    _currentTicket.message,
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  6.height,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _currentTicket.status,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          _currentTicket.status,
                                        ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: AppText(
                                      _getStatusText(_currentTicket.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(
                                        _currentTicket.status,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            8.width,
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reply Thread List
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _onRefresh(context),
                      child: Builder(
                        builder: (context) {
                          if (state is SupportLoading &&
                              _cachedReplies.isEmpty) {
                            return const Center(child: CustomLoader());
                          }
                          if (_cachedReplies.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline,
                                          color: Colors.white24,
                                          size: 48,
                                        ),
                                        12.height,
                                        AppText(
                                          context
                                              .l10n
                                              .noRepliesYetSupportTeamWillRespondShortly,
                                          color: Colors.white38,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            itemCount: _cachedReplies.length,
                            itemBuilder: (context, index) {
                              final reply = _cachedReplies[index];
                              final authState = context.read<AuthBloc>().state;
                              final isMe =
                                  authState is AuthenticatedState &&
                                  reply.senderId == authState.user.id;
                              return _buildReplyBubble(reply, isMe);
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Input Box
                  _buildInputArea(
                    context,
                    state is SupportActionLoading,
                    isClosed: _currentTicket.status == TicketStatus.closed,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyBubble(TicketReplyEntity reply, bool isMe) {
    final senderLabel = isMe ? 'You' : (reply.senderName ?? 'Support Agent');

    final time = reply.createdAt.toString().split(' ')[1].substring(0, 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(
                Icons.support_agent,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            8.width,
          ],

          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                        minWidth: 100,
                      ),
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : AppColors.lightBackgroundColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 12),
                            ),
                            border: Border.all(
                              color: isMe
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : Colors.white12,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Sender name
                              AppText(
                                senderLabel,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? AppColors.primary
                                    : Colors.white70,
                              ),
                              2.height,

                              /// Message
                              if (reply.message.isNotEmpty) ...[
                                AppText(
                                  reply.message,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ],

                              /// Attachments
                              if (reply.attachmentUrls.isNotEmpty) ...[
                                2.height,
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: reply.attachmentUrls
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _buildAttachmentThumb(
                                          entry.value,
                                          allUrls: reply.attachmentUrls,
                                          initialIndex: entry.key,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    5.height,

                    /// Time
                    Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: AppText(
                        time,
                        fontSize: 10,
                        height: 1,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isMe) ...[
            8.width,
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white10,
              child: const Icon(Icons.person, size: 18, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentThumb(
    String url, {
    List<String>? allUrls,
    int initialIndex = 0,
  }) {
    final urlsList = allUrls ?? [url];
    return GestureDetector(
      onTap: () => _openImageGalleryLightbox(urlsList, initialIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AppImage(
          imageUrl: url,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext cubitContext,
    bool isSending, {
    bool isClosed = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        color: AppColors.lightBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isClosed)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 12.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          context
                              .l10n
                              .thisTicketIsClosedMessagingIsDisabledUntilItIsReopenedBySupport,
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ValueListenableBuilder<List<File>>(
              valueListenable: _selectedFiles,
              builder: (context, files, _) {
                if (files.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: files.map((file) {
                      return UploadedFileItemWidget(
                        file: file,
                        onRemove: isClosed
                            ? () {}
                            : () {
                                _selectedFiles.value = List.from(
                                  _selectedFiles.value,
                                )..remove(file);
                              },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: isClosed ? Colors.white24 : Colors.white70,
                  ),
                  onPressed: (isSending || isClosed) ? null : _pickFile,
                ),
                3.width,
                Expanded(
                  child: AppTextField(
                    controller: _replyController,
                    enabled: !isClosed,
                    readOnly: isClosed,
                    hintText: isClosed
                        ? context.l10n.ticketIsClosed
                        : context.l10n.writeYourMessage,
                    borderColor: Colors.transparent,
                    textColor: isClosed ? Colors.white38 : Colors.white,
                    minLines: 1,
                    maxLines: null,
                    expands: false,
                    fillColor: isClosed
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.mainBackgroundColor,
                  ),
                ),
                8.width,
                IconButton(
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: isClosed ? Colors.white24 : AppColors.primary,
                        ),
                  onPressed: (isSending || isClosed)
                      ? null
                      : () => _sendReply(cubitContext),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
