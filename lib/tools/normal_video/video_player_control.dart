import 'dart:async';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movie_flz/tools/normal_video/video_player_slider.dart';
import 'package:video_player/video_player.dart';

import './time.dart';
import 'controller_widget.dart';

class VideoPlayerControl extends StatefulWidget {
  final Function share;
  final Function(bool) full;
  VideoPlayerControl({
    Key key,
    this.share,
    this.full,
  }) : super(key: key);

  @override
  VideoPlayerControlState createState() => VideoPlayerControlState();
}

class VideoPlayerControlState extends State<VideoPlayerControl> {
  VideoPlayerController get controller =>
      ControllerWidget.of(context).controller;
  bool get videoInit => ControllerWidget.of(context).videoInit;
  String get title => ControllerWidget.of(context).title;
  // 记录video播放进度
  Duration _position = Duration(seconds: 0);
  Duration _totalDuration = Duration(seconds: 0);
  Timer _timer; // 计时器，用于延迟隐藏控件ui
  bool _hidePlayControl = true; // 控制是否隐藏控件ui
  double _playControlOpacity = 0; // 通过透明度动画显示/隐藏控件ui
  /// 记录是否全屏
  bool get _isFullScreen =>
      MediaQuery.of(context).orientation == Orientation.landscape;
  bool lock = false; //是否锁定

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _playOrPause,
      onTap: _togglePlayControl,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: WillPopScope(
          child: Offstage(
            offstage: _hidePlayControl,
            child: AnimatedOpacity(
                // 加入透明度动画
                opacity: _playControlOpacity,
                duration: Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Offstage(
                      offstage: !_isFullScreen,
                      child: SizedBox(
                        width: ScreenUtil().setHeight(40),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Offstage(offstage: lock, child: _top()),
                          _middle(),
                          Offstage(offstage: lock, child: _bottom(context)),
                        ],
                      ),
                    ),
                  ],
                )),
          ),
          onWillPop: _onWillPop,
        ),
      ),
    );
  }

  // 拦截返回键
  Future<bool> _onWillPop() async {
    if (_isFullScreen) {
      _toggleFullScreen();
      return false;
    }
    return true;
  }

  // 供父组件调用刷新页面，减少父组件的build
  void setPosition({position, totalDuration}) {
    setState(() {
      _position = position;
      _totalDuration = totalDuration;
    });
  }

  Widget _bottom(BuildContext context) {
    return Container(
      // 底部控件的容器
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // 来点黑色到透明的渐变优雅一下
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, .7),
            Color.fromRGBO(0, 0, 0, .5),
            Color.fromRGBO(0, 0, 0, .5),
            Color.fromRGBO(0, 0, 0, .5),
            Color.fromRGBO(0, 0, 0, .5),
            Color.fromRGBO(0, 0, 0, .4),
            Color.fromRGBO(0, 0, 0, .2),
            Color.fromRGBO(0, 0, 0, .1),
            Color.fromRGBO(0, 0, 0, .0),
          ],
        ),
      ),
      child: Row(
        // 加载完成时才渲染,flex布局
        children: <Widget>[
          Container(
            width: ScreenUtil().setHeight(80),
            height: ScreenUtil().setHeight(80),
            child: IconButton(
              // 播放按钮
              padding: EdgeInsets.zero,
              iconSize: 30,
              icon: Icon(
                // 根据控制器动态变化播放图标还是暂停
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: _playOrPause,
            ),
          ),
          Container(
            // 当前播放时间
            child: Text(
              '${_position == null ? '00:00' : videoTime(_position.inMilliseconds)}',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            // 相当于前端的flex: 1
            child: Container(
              padding: EdgeInsets.only(
                  left: ScreenUtil().setWidth(4),
                  right: ScreenUtil().setWidth(4)),
              child: VideoPlayerSlider(
                startPlayControlTimer: _startPlayControlTimer,
                timer: _timer,
              ),
            ),
          ),
          Container(
            // 播放时间
            child: Text(
              '${_totalDuration == null ? '00:00' : videoTime(_totalDuration.inMilliseconds)}',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Container(
            width: ScreenUtil().setHeight(80),
            height: ScreenUtil().setHeight(80),
            child: IconButton(
              // 播放按钮
              // padding: EdgeInsets.zero,
              iconSize: 26,
              icon: Icon(
                // 根据当前屏幕方向切换图标
                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: () {
                // 点击切换是否全屏
                _toggleFullScreen();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget myIcon(IconData icon, {Function onTap, double size = 36}) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadiusDirectional.all(Radius.circular(size))),
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Icon(
          icon,
          size: size,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _middle() {
    return Expanded(
      child: Row(
        children: <Widget>[
          myIcon(lock ? Icons.lock_open : Icons.lock_outline, size: 24,
              onTap: () {
            setState(() {
              lock = !lock;
            });
          }),
          Expanded(child: SizedBox(width: 0)),
          Offstage(
              offstage: lock,
              child: myIcon(
                // 根据控制器动态变化播放图标还是暂停
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                onTap: _playOrPause,
              )),
          Expanded(child: SizedBox(width: 0)),
          Offstage(
              offstage: lock,
              child: myIcon(Icons.live_tv,
                  size: 24, onTap: widget.share ?? () {})),
        ],
      ),
    );
  }

  Widget _top() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        boxShadow: [
          // 阴影
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .5),
              blurRadius: 20,
              spreadRadius: 10,
              offset: Offset(0, -1))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          //在最上层或者不是横屏则隐藏按钮
          ModalRoute.of(context).isFirst && !_isFullScreen
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: backPress),
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          //在最上层或者不是横屏则隐藏按钮
          ModalRoute.of(context).isFirst && !_isFullScreen
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.transparent,
                  ),
                  onPressed: () {},
                ),
        ],
      ),
    );
  }

  void backPress() {
    print(_isFullScreen);
    // 如果是全屏，点击返回键则关闭全屏，如果不是，则系统返回键
    if (_isFullScreen) {
      _toggleFullScreen();
    } else if (ModalRoute.of(context).isFirst) {
      SystemNavigator.pop();
    } else {
      Navigator.pop(context);
    }
  }

  void _playOrPause() async {
    if (lock) return;

    /// 同样的，点击动态播放或者暂停
    if (videoInit) {
      controller.value.isPlaying
          ? await controller.pause()
          : await controller.play();
      setState(() {}); //更新界面
      _startPlayControlTimer(); // 操作控件后，重置延迟隐藏控件的timer
    }
  }

  void _togglePlayControl() {
    setState(() {
      if (_hidePlayControl) {
        /// 如果隐藏则显示
        _hidePlayControl = false;
        _playControlOpacity = 1;
        _startPlayControlTimer(); // 开始计时器，计时后隐藏
      } else {
        /// 如果显示就隐藏
        if (_timer != null) _timer.cancel(); // 有计时器先移除计时器
        _playControlOpacity = 0;
        Future.delayed(Duration(milliseconds: 500)).whenComplete(() {
          _hidePlayControl = true; // 延迟500ms(透明度动画结束)后，隐藏
        });
      }
    });
  }

  void _startPlayControlTimer() {
    /// 计时器，用法和前端js的大同小异
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 3), () {
      setState(() {
        _playControlOpacity = 0;
        _hidePlayControl = true;
      });
    });
  }

  void _toggleFullScreen() {
    if (widget.full != null) widget.full(_isFullScreen);
    setState(() {
      if (_isFullScreen) {
        /// 如果是全屏就切换竖屏
        AutoOrientation.portraitAutoMode();

        ///显示状态栏，与底部虚拟操作按钮
        SystemChrome.setEnabledSystemUIOverlays(
            [SystemUiOverlay.top, SystemUiOverlay.bottom]);
      } else {
        AutoOrientation.landscapeRightMode();

        ///关闭状态栏，与底部虚拟操作按钮
        SystemChrome.setEnabledSystemUIOverlays(
            [SystemUiOverlay.top, SystemUiOverlay.bottom]);
      }
      _startPlayControlTimer(); // 操作完控件开始计时隐藏
    });
  }
}
