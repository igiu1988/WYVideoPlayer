#旋转及全屏
其实更多的讨论是关于旋转，全屏只是在旋转后的附带变换。

## 首先要知道的事
1. 我们是再模仿搜狐视频的旋转效果，搜狐视频的旋转效果是
	* 默认是竖屏播放，要想横屏必须手动点全屏按键；
	* 全屏后，如果系统的“设备旋转”未锁定，可以旋转设备来切换左横屏或者右横屏，如果“设备旋转”锁定，则全屏后不会自动旋转.
2. 这个播放器是继承UIView的，所以在旋转时是调整`WYVideoPlayerView`即可
3. 播放器旋转要独立于与整个程序的旋转
4. 播放器旋转只控制其自身。播放器提供回调函数，以供controller知道在何时如何调整其它view。

## 禁用自动旋转
如上面提到：播放器旋转要独立于与整个程序的旋转。所以要禁用`WYVideoPlayerView`所在controller的旋转

可以参考`WYMoviePlayerController`

```
- (BOOL)shouldAutorotate
{
    return NO;
}
```

## 旋转事件的监听

```
// 监听设备旋转。如果旋转被用户锁定，系统就不再会发该通知
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
```

详细见`WYVideoPlayerView`中的`deviceOrientationDidChange`方法、`fullScreen`方法还有`changeOrientationTo:rotationAngle`方法。

## 在有导航栏时的处理
如果controller处于NavigationController中时，直接使用如下代码旋转状态发现不好使

```
[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
```

Google了一下，说要在对应的controller里给UINavigationController做点扩展，详见`WYMoviePlayerController`中的`UINavigationController (Rotation)
`。这么弄的确好使，具体忘记原因了。 -_-!


## 全屏
在ios6.0里，播放器所在的ViewController要设置`wantsFullScreenLayout＝YES`，这样controller里的view的坐标都会从0开始，就像ios7那样。

<font style="color:red">注意:</font>

> 旋转时全屏，必然要涉及改变view的位置及大小，务必使用`view.center`及`view.bounds`来更改
