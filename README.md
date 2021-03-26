# Hang Helper
An iOS application to get the measurement between two nodes as well as generating a grid on a vertical plane.

## Description
Using Swift ARKit to determine the measurement in feet and inches between two points. Using two points, ideally from an object you know is level, a grid can also be generated to help the user get a idea of where to hang objects on the wall.

### App Screencast
![](ProjectGif/project.gif)


### Usage
To be able to use the app, a plane needs to be detected first, so wait until a green notice on top that says "Plane Detected". After a plane is detected tap anywhere on the screen to get two points to get the length between that two points. 

To get a grid from two points, tap on the upper right hand corner to switch to Grid Mode. After you are on Grid Mode just tap two points preferably on an object that you know is level. 

## Built With
* [Xcode - 12.3](https://developer.apple.com/xcode/) - The IDE used
* [Swift - 5.1.4](https://developer.apple.com/swift/) - Programming language