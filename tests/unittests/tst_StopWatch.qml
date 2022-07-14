/*
 * Copyright 2013 Canonical Ltd.
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
 *
 */

import QtQuick 2.12
import QtTest 1.0
import "../../"
import "../../.." //Needed for out of source build

TestCase {
    name: "StopWatch"

    function test_time_format_hours() {
        stopWatch.time = 12345
        compare(stopWatch.label, "03:25:45", "Time not calculated correctly")
    }

    function test_time_format_calc() {
        stopWatch.time = 1234
        compare(stopWatch.label, "20:34", "Time not calculated correctly")
    }

    function test_time_format_pad() {
        stopWatch.time = 5
        compare(stopWatch.label, "00:05", "Time not calculated correctly")
    }

    function test_time_negative() {
        stopWatch.time = -1234
        compare(stopWatch.label, "-20:34", "Time not calculated correctly")
    }

    StopWatch {
        id: stopWatch
    }
}
