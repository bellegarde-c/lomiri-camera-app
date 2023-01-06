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

Loader {
    id: loader

    property var camera
    property bool touchAcquired: loader.item ? loader.item.touchAcquired : false
    property real revealProgress: loader.item ? loader.item.revealProgress : 0
    property var controls: loader.item ? loader.item.controls : null
    property var settings: loader.item.settings
    property bool readOnly : false
    property bool readyForCapture
    property int sensorOrientation

    function showFocusRing(x, y) {
        loader.item.showFocusRing(x, y);
    }

    Component.onCompleted: {
        var overlayType = !readOnly ? "ViewFinderOverlay.qml" : "BarcodeReaderOverlay.qml"
        loader.setSource(overlayType, { "camera": loader.camera
                                                  });
    }

    onLoaded: {
        loader.item.readyForCapture = Qt.binding(function() { return loader.readyForCapture });
        loader.item.sensorOrientation = Qt.binding(function() { return loader.sensorOrientation });
    }
}
