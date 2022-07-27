import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:flutter_tex/src/views/web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeXViewState extends State<TeXView> with AutomaticKeepAliveClientMixin {
  WebViewPlusController? _controller;
  final ValueNotifier<double> _height = ValueNotifier<double>(minHeight);

  String? _lastData;
  bool _pageLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    updateKeepAlive();
    _initTeXView();
    return ValueListenableBuilder<double>(
        valueListenable: _height,
        builder: (context, value, _) {
          return Stack(
            children: [
              SizedBox(
                height: _height.value,
                child: WebViewPlus(
                  onPageFinished: (message) {
                    _pageLoaded = true;
                    _initTeXView();
                  },
                  initialUrl: "packages/flutter_tex/js/${widget.renderingEngine?.name ?? 'katex'}/index.html",
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
                  backgroundColor: Colors.transparent,
                  allowsInlineMediaPlayback: true,
                  javascriptChannels: {
                    JavascriptChannel(
                        name: 'TeXViewRenderedCallback',
                        onMessageReceived: (jm) async {
                          double height = double.parse(jm.message);
                          if (_height.value != height) {
                            _height.value=height;
                          }
                          widget.onRenderFinished?.call(height);
                        }),
                    JavascriptChannel(
                        name: 'OnTapCallback',
                        onMessageReceived: (jm) {
                          widget.child.onTapCallback(jm.message);
                        })
                  },
                  javascriptMode: JavascriptMode.unrestricted,
                ),
              ),
              Visibility(
                  visible: widget.loadingWidgetBuilder?.call(context) != null
                      ? _height.value == minHeight
                      ? true
                      : false
                      : false,
                  child: widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink()
              )
            ],
          );
        }
    );
  }

  void _initTeXView() {
    if (_pageLoaded && _controller != null && getRawData(widget) != _lastData) {
      if (widget.loadingWidgetBuilder != null) _height.value = minHeight;
      _controller!.webViewController
          .runJavascript("initView(${getRawData(widget)})");
      _lastData = getRawData(widget);
    }
  }
}
