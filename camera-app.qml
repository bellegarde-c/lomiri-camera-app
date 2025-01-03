/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Window 2.2
import QtMultimedia 5.0
import Lomiri.Components 1.3
import Lomiri.Action 1.1 as LomiriActions
import Lomiri.Content 1.3
import CameraApp 0.1
import Qt.labs.settings 1.0
import QtSensors 5.2

Window {
    id: main
    objectName: "main"
    width: Math.min(Screen.width, height * viewFinderView.aspectRatio)
    height: Math.min(Screen.height, units.gu(80))
    color: "black"
    title: i18n.tr("Camera")
    // special flag only supported by Unity8/MIR so far that hides the shell's
    // top panel in Staged mode
    flags: Qt.Window | 0x00800000

      Settings {
        id: appSettings

        property bool blurEffects:true
        property bool blurEffectsPreviewOnly: true
      }

    function toggleFullScreen() {
        if (main.visibility !== Window.FullScreen) {
            main.visibility = Window.FullScreen;
            setFullscreen(true);
        } else {
            main.visibility = Window.Windowed;
        }
    }

    function exitFullScreen() {
        main.visibility = Window.Windowed;
    }

    LomiriActions.ActionManager {
        actions: [
            LomiriActions.Action {
                text: i18n.tr("Flash")
                keywords: i18n.tr("Light;Dark")
            },
            LomiriActions.Action {
                text: i18n.tr("Flip Camera")
                keywords: i18n.tr("Front Facing;Back Facing")
            },
            LomiriActions.Action {
                text: i18n.tr("Shutter")
                keywords: i18n.tr("Take a Photo;Snap;Record")
            },
            LomiriActions.Action {
                text: i18n.tr("Mode")
                keywords: i18n.tr("Stills;Video")
                enabled: false
            },
            LomiriActions.Action {
                text: i18n.tr("White Balance")
                keywords: i18n.tr("Lighting Condition;Day;Cloudy;Inside")
            }
        ]

        onQuit: {
            Qt.quit()
        }
    }

    Component.onCompleted: {
        i18n.domain = "lomiri-camera-app";
        i18n.bindtextdomain("lomiri-camera-app", i18nDirectory);
        main.show();
    }

    readonly property int sensorOrientation: orientationSensor.reading ? orientationSensor.reading.orientation : OrientationReading.TopUp
    readonly property var angleToSensorOrientation: {1 /* OrientationReading.TopUp */: 0,
                                                      4 /* OrientationReading.LeftUp */: 90,
                                                      2 /* OrientationReading.TopDown */: 180,
                                                      3 /* OrientationReading.RightUp */: 270}

    readonly property int sensorOrientationAngle: angleToSensorOrientation[sensorOrientation]
    readonly property int screenOrientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    
    readonly property int staticRotationAngle: screenOrientationAngle == sensorOrientationAngle ? screenOrientationAngle : sensorOrientationAngle
    readonly property int orientedRotationAngle: if (screenOrientationAngle != sensorOrientationAngle) {
                                                      if (screenOrientationAngle > 0) {
                                                          sensorOrientationAngle - screenOrientationAngle
                                                      } else {
                                                          staticRotationAngle
                                                      }
                                                  } else {
                                                      0
                                                  }
    // Checks if the sensor is different than the screen orientation (Landscape or Portrait)
    readonly property bool sensorHasDifferentOrientation: Math.abs(orientedRotationAngle) == 90 || Math.abs(orientedRotationAngle) == 270

    OrientationSensor {
        id: orientationSensor
        active: true
    }

    Flickable {
        id: viewSwitcher
        objectName: "viewSwitcher"
        anchors.fill: parent
        flickableDirection: state == "PORTRAIT" || state == "INVERTED_PORTRAIT" ? Flickable.HorizontalFlick : Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Keys.onPressed: {
            if (event.key == Qt.Key_F11) {
                main.toggleFullScreen();
                event.accepted = true;
            } else if (event.key == Qt.Key_WebCam || event.key == Qt.Key_Camera) {
                viewFinderView.finderOverlay.item.triggerShoot();
                event.accepted = true;
            }
        }
        Keys.onEscapePressed: main.exitFullScreen()


        property real panesMargin: units.gu(1)
        property real ratio
        property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
        property var angleToOrientation: {0: "PORTRAIT",
                                          90: "LANDSCAPE",
                                          180: "INVERTED_PORTRAIT",
                                          270: "INVERTED_LANDSCAPE"}
        state: angleToOrientation[orientationAngle]
        states: [
            State {
                name: "PORTRAIT"
                StateChangeScript {
                    script: {
                        viewSwitcher.ratio = viewSwitcher.ratio;
                        viewSwitcher.contentWidth = Qt.binding(function() { return viewSwitcher.width * 2 + viewSwitcher.panesMargin });
                        viewSwitcher.contentHeight = Qt.binding(function() { return viewSwitcher.height });
                        galleryView.x = Qt.binding(function() { return viewFinderView.width + viewSwitcher.panesMargin });
                        galleryView.y = 0;
                        viewFinderView.x = 0;
                        viewFinderView.y = 0;
                        viewSwitcher.positionContentAtRatio(viewSwitcher.ratio)
                        viewSwitcher.ratio = Qt.binding(function() { return viewSwitcher.contentX / viewSwitcher.contentWidth });
                    }
                }
            },
            State {
                name: "INVERTED_PORTRAIT"
                StateChangeScript {
                    script: {
                        viewSwitcher.ratio = viewSwitcher.ratio;
                        viewSwitcher.contentWidth = Qt.binding(function() { return viewSwitcher.width * 2 + viewSwitcher.panesMargin });
                        viewSwitcher.contentHeight = Qt.binding(function() { return viewSwitcher.height });
                        galleryView.x = 0;
                        galleryView.y = 0;
                        viewFinderView.x = Qt.binding(function() { return viewFinderView.width + viewSwitcher.panesMargin });
                        viewFinderView.y = 0;
                        viewSwitcher.positionContentAtRatio(viewSwitcher.ratio)
                        viewSwitcher.ratio = Qt.binding(function() { return 0.5 - viewSwitcher.contentX / viewSwitcher.contentWidth });
                    }
                }
            },
            State {
                name: "LANDSCAPE"
                StateChangeScript {
                    script: {
                        viewSwitcher.ratio = viewSwitcher.ratio;
                        viewSwitcher.contentWidth = Qt.binding(function() { return viewSwitcher.width });
                        viewSwitcher.contentHeight = Qt.binding(function() { return viewSwitcher.height * 2 + viewSwitcher.panesMargin });
                        galleryView.x = 0;
                        galleryView.y = Qt.binding(function() { return viewFinderView.height + viewSwitcher.panesMargin });
                        viewFinderView.x = 0;
                        viewFinderView.y = 0;
                        viewSwitcher.positionContentAtRatio(viewSwitcher.ratio)
                        viewSwitcher.ratio = Qt.binding(function() { return viewSwitcher.contentY / viewSwitcher.contentHeight });
                    }
                }
            },
            State {
                name: "INVERTED_LANDSCAPE"
                StateChangeScript {
                    script: {
                        viewSwitcher.ratio = viewSwitcher.ratio;
                        viewSwitcher.contentWidth = Qt.binding(function() { return viewSwitcher.width });
                        viewSwitcher.contentHeight = Qt.binding(function() { return viewSwitcher.height * 2 + viewSwitcher.panesMargin });
                        galleryView.x = 0;
                        galleryView.y = 0;
                        viewFinderView.x = 0;
                        viewFinderView.y = Qt.binding(function() { return galleryView.height + viewSwitcher.panesMargin });
                        viewSwitcher.positionContentAtRatio(viewSwitcher.ratio)
                        viewSwitcher.ratio = Qt.binding(function() { return 0.5 - viewSwitcher.contentY / viewSwitcher.contentHeight });
                    }
                }
            }
        ]
        interactive: !viewFinderView.touchAcquired && !galleryView.touchAcquired
                     && !viewFinderView.camera.photoCaptureInProgress
                     && !viewFinderView.camera.timedCaptureInProgress

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        property bool settling: false
        property bool switching: false
        property real settleVelocity: units.dp(5000)

        function settle() {
            settling = true;
            var velocity;
            if (flickableDirection == Flickable.HorizontalFlick) {
                if (horizontalVelocity < 0 || visibleArea.xPosition <= 0.05 || (horizontalVelocity == 0 && visibleArea.xPosition <= 0.25)) {
                    // FIXME: compute velocity better to ensure it reaches rest position (maybe in a constant time)
                    velocity = settleVelocity;
                } else {
                    velocity = -settleVelocity;
                }
                flick(velocity, 0);
            } else {
                if (verticalVelocity < 0 || visibleArea.yPosition <= 0.05 || (verticalVelocity == 0 && visibleArea.yPosition <= 0.25)) {
                    // FIXME: compute velocity better to ensure it reaches rest position (maybe in a constant time)
                    velocity = settleVelocity;
                } else {
                    velocity = -settleVelocity;
                }
                flick(0, velocity);
            }
        }

        function switchToViewFinder() {
            cancelFlick();
            switching = true;
            if (state == "PORTRAIT") {
                flick(settleVelocity, 0);
            } else if (state == "INVERTED_PORTRAIT") {
                flick(-settleVelocity, 0);
            } else if (state == "LANDSCAPE") {
                flick(0, settleVelocity);
            } else if (state == "INVERTED_LANDSCAPE") {
                flick(0, -settleVelocity);
            }
        }

        function positionContentAtRatio(ratio) {
            if (state == "PORTRAIT") {
                viewSwitcher.contentX = ratio * viewSwitcher.contentWidth;
            } else if (state == "INVERTED_PORTRAIT") {
                viewSwitcher.contentX = (0.5 - ratio) * viewSwitcher.contentWidth;
            }  else if (state == "LANDSCAPE") {
                viewSwitcher.contentY = ratio * viewSwitcher.contentHeight;
            } else if (state == "INVERTED_LANDSCAPE") {
                viewSwitcher.contentY = (0.5 - ratio) * viewSwitcher.contentHeight;
            }
        }

        onContentWidthChanged: positionContentAtRatio(viewSwitcher.ratio)
        onContentHeightChanged: positionContentAtRatio(viewSwitcher.ratio)

        onMovementEnded: {
            // go to a rest position as soon as user stops interacting with the Flickable
            settle();
        }

        onFlickStarted: {
            // cancel user triggered flicks
            if (!settling && !switching) {
                cancelFlick();
            }
        }

        onFlickingHorizontallyChanged: {
            // use flickingHorizontallyChanged instead of flickEnded because flickEnded
            // is not called when a flick is interrupted by the user
            if (!flickingHorizontally) {
                if (settling) {
                    settling = false;
                }
                if (switching) {
                    switching = true;
                }
            }
        }

        onHorizontalVelocityChanged: {
            // FIXME: this is a workaround for the lack of notification when
            // the user manually interrupts a flick by pressing and releasing
            if (horizontalVelocity == 0 && !atXBeginning && !atXEnd && !settling && !moving) {
                settle();
            }
        }

        onFlickingVerticallyChanged: {
            // use flickingHorizontallyChanged instead of flickEnded because flickEnded
            // is not called when a flick is interrupted by the user
            if (!flickingVertically) {
                if (settling) {
                    settling = false;
                }
                if (switching) {
                    switching = true;
                }
            }
        }

        onVerticalVelocityChanged: {
            // FIXME: this is a workaround for the lack of notification when
            // the user manually interrupts a flick by pressing and releasing
            if (verticalVelocity == 0 && !atYBeginning && !atYEnd && !settling && !moving) {
                settle();
            }
        }

        ViewFinderView {
            id: viewFinderView
            width: viewSwitcher.width
            height: viewSwitcher.height
            overlayVisible: !viewSwitcher.moving && !viewSwitcher.flicking
            inView: viewSwitcher.ratio < 0.5
            focus: !galleryView.focus
            opacity: inView ? 1.0 : 0.0
            onPhotoTaken: {
                galleryView.prependMediaToModel(filePath);
                galleryView.showLastPhotoTaken();
            }
            onVideoShot: {
                galleryView.prependMediaToModel(filePath);
                galleryView.showLastPhotoTaken();
                galleryView.precacheThumbnail(filePath);
            }
        }

        GalleryViewLoader {
            id: galleryView
            width: viewSwitcher.width
            height: viewSwitcher.height
            inView: viewSwitcher.ratio > 0.0
            focus: inView
            onExit: viewSwitcher.switchToViewFinder()
            opacity: inView ? 1.0 : 0.0
        }
    }

    property bool contentExportMode: transfer !== null
    property var transfer: null
    property var transferContentType: transfer ? transfer.contentType : "image"

    function exportContent(urls) {
        if (!main.transfer) return;

        var item;
        var items = [];
        for (var i=0; i<urls.length; i++) {
            item = contentItemComponent.createObject(main.transfer, {"url": urls[i]});
            items.push(item);
        }
        main.transfer.items = items;
        main.transfer.state = ContentTransfer.Charged;
        main.transfer = null;
    }

    function cancelExport() {
        main.transfer.state = ContentTransfer.Aborted;
        main.transfer = null;
    }

    Component {
        id: contentItemComponent
        ContentItem {
        }
    }

    Connections {
        target: ContentHub
        onExportRequested: {
            viewSwitcher.switchToViewFinder();

            if (transfer.contentType === ContentType.Videos) {
                viewFinderView.captureMode = Camera.CaptureVideo;
            } else {
                viewFinderView.captureMode = Camera.CaptureStillImage;
            }
            main.transfer = transfer;
        }
    }
}
