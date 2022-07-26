/*
 * Copyright (C) 2012 Canonical, Ltd.
 *
 * Authors:
 *  Ugo Riboni <ugo.riboni@canonical.com>
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

// Qt
#include <QGuiApplication>
#include <QtQml/QQmlDebuggingEnabler>

// local
#include "cameraapplication.h"
#include "config.h"

#include <QDebug>

static QQmlDebuggingEnabler debuggingEnabler(false);

int main(int argc, char** argv)
{
    QGuiApplication::setApplicationName("com.ubuntu.camera");
    // Necessary for Qt.labs.settings to work
    // Ref.: https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1354321
    QCoreApplication::setOrganizationDomain(QGuiApplication::applicationName());

    //Inject versioning strings from CI
    QCoreApplication::setApplicationVersion(QStringLiteral(BUILD_VERSION));

    CameraApplication application(argc, argv);

    if (!application.setup()) {
        return 0;
    }

    return application.exec();
}

