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

#ifndef CAMERAAPPLICATION_H
#define CAMERAAPPLICATION_H

#include <QtQml/QQmlApplicationEngine>
#include <QGuiApplication>

class QDate;
enum CameraMode : unsigned short;

class CameraApplication : public QGuiApplication
{
    Q_OBJECT
    Q_PROPERTY(bool desktopMode READ isDesktopMode CONSTANT)

public:
    CameraApplication(int &argc, char **argv);
    virtual ~CameraApplication();
    bool setup();
    bool isDesktopMode() const;

Q_SIGNALS:

private:
    QScopedPointer<QQmlApplicationEngine> m_engine;
    CameraMode m_mode;
};

#endif // CAMERAAPPLICATION_H
