/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the QWebChannel module on Qt labs.
**
** $QT_BEGIN_LICENSE:LGPL$
** No Commercial Usage
** This file contains pre-release code and may not be distributed.
** You may use this file in accordance with the terms and conditions
** contained in the Technology Preview License Agreement accompanying
** this package.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain additional
** rights.  These rights are described in the Nokia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** If you have questions regarding the use of this file, please contact
** Nokia at qt-info@nokia.com.
**
**
**
**
**
**
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0

import Qt.labs 1.0
import Qt.labs.WebChannel 1.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0

Rectangle {
    QtMetaObjectPublisher {
        id: publisher
    }

    TestObject {
        id: testObject
    }

    WebChannel {
        id: webChannel
        onExecute: {
            var payload = JSON.parse(requestData);
            var object = publisher.namedObject(payload.object);
            var ret;
            console.log(requestData);
            if (payload.type == "Qt.invokeMethod") {
                ret = (object[payload.method])(payload.args);
            } else if (payload.type == "Qt.connectToSignal") {
                object[payload.signal].connect(
                    function(a,b,c,d,e,f,g,h,i,j) {
                        broadcast("Qt.signal", JSON.stringify({object: payload.object, signal: payload.signal, args: [a,b,c,d,e,f,g,h,i,j]}));
                });
            } else if (payload.type == "Qt.getProperty") {
                ret = object[payload.property];
            } else if (payload.type == "Qt.setProperty") {
                object[payload.property] = payload.value;
            } else if (payload.type == "Qt.getObjects") {
                var objectNames = publisher.objectNames;
                for (var i = 0; i < objectNames.length; ++i) {
                    var name = objectNames[i];
                    var o = publisher.namedObject(name);
                    addObject(name, o);
                }
            }

            response.send(JSON.stringify(ret));
        }

        function addObject(name, object)
        {
            publisher.addObject(name, object);
            var metaData = { name: name, data: publisher.classInfoForObject(object) };
            broadcast("Qt.addToWindowObject", JSON.stringify(metaData));
        }

        onBaseUrlChanged: addObject("testObject", testObject)
    }

    width: 480
    height: 800

    WebView {
        anchors.fill: parent
        url: "index.html?webChannelBaseUrl=" + webChannel.baseUrl
        experimental.preferences.developerExtrasEnabled: true
    }
}