#WYVideoPlayer

基于AV Foundation的视频播放器。<font color=red size=20>还没有做完。</font>
## 系统兼容
ios6.0及以上

## 旋转
* 使用CGAffineTransform来控制相关的旋转
* 使用UIDeviceOrientationDidChangeNotification来检测设备是否进行旋转 


## 全屏
* 在ios6.0里使用wantsFullScreenLayout＝YES来达到全屏播放的处理。
* 使用view.center及view.bounds来改变view的位置及大小，再rotateTransform，这样动画就会按照我们的旨意去运行


# 类

主要的两个类的描述
## WYVideoPlayerView
1. play view 只提供播放的基本控制及信息。只提供控制接口，不提供控制相关的UI. 全屏，播放，暂停，进度，总时长。
2. play view 不提供手势操作，想要实现在你自己的view controller里自己加。一般来说有单击隐藏控制栏，双击全屏。
3. 提供了各种回调机制（block）
4. 使用AVQueuePlayer，在视频退出时执行`queuePlayer removeAllItems`以停止视频加载
 
## WYMoviePlayerController
1. 示例了旋转操作的处理，及有UINavigationController时要如何处理才能旋转
2. 示例了手势处理


# 参考

[AV Foundation Programming Guide](https://developer.apple.com/library/mac/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/03_Editing.html) 和各种google搜索
