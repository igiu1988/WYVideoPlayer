#WYVideoPlayer
简单的说就是在模仿搜狐视频播放器。搜狐视频的播放器在全屏动画上，过渡最流畅


## 主要功能描述
1. 加载远程或本地视频
2. 旋转、全屏控制
3. 提供了视频播放的基本操作
4. 网络环境改变的监控及处理
5. app状态改变的控制
6. 双击全屏；单击隐藏播放控制
7. 记录位置播放。触发点：后台时，popController时，暂停时。其实这些都会触发暂停操作，所以简单的说就是在每次暂停时都会记录。记录的时间为currentTime减去某个值，再播放时由于是从先前的几秒位置开始，这样应该有助于记忆衔接。相关代码在`saveLastPlayTime`方法里

## 系统兼容
ios6.0及以上

## 使用
代码详见`WYMoviePlayerController`中的`setupPlayer`方法

## 主要类描述
### WYVideoPlayerView
1. play view 只提供播放的基本控制及信息。只提供控制接口，不提供控制相关的UI. 全屏，播放，暂停，进度，总时长。
2. play view 不提供手势操作，想要实现在你自己的view controller里自己加。一般来说有单击隐藏控制栏，双击全屏。
3. 提供了各种回调函数（block）
4. 使用AVQueuePlayer播放视频，在视频退出时执行`queuePlayer removeAllItems`以停止视频加载
 
### WYMoviePlayerController
1. 示例了WYVideoPlayerView在旋转时，controller要如何配合。详见项目里的文档`How to Rotate Like SoHu Video.md`
2. 示例了两个手势处理

## 旋转及全屏
详见项目中的文档：How to Rotate Like SoHu Video.md


## 问题（bug）列表
下面所说的问题，要么是的确存在这个bug，要么就是还不确定，需要测试验证


0. 断网再连接，应该可以自动继续缓冲及自动播放; ItemPlaybackLikelyToKeepUpContext这个observer的执行事件有问题

