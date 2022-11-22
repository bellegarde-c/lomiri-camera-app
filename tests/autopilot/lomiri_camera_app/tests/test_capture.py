# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012, 2015 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Camera App"""

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals
from wand.image import Image
from MediaInfoDLL3 import MediaInfo, Stream

from lomiri_camera_app.tests import CameraAppTestCase

import unittest
import time
import os
import glob


class TestCapture(CameraAppTestCase):
    """Tests the main camera features"""

    """ This is needed to wait for the application to start.
        In the testfarm, the application may take some time to show up."""
    def setUp(self):
        super(TestCapture, self).setUp()
        self.pictures_dir = os.path.expanduser("~/Pictures/camera.ubports")
        self.videos_dir = os.path.expanduser("~/Videos/camera.ubports")

    """Test taking a picture"""
    def test_take_picture(self):
        exposure_button = self.main_window.get_exposure_button()

        # Remove all pictures from self.pictures_dir that match our pattern
        files = [
            f for f in os.listdir(self.pictures_dir)
            if f[0:5] == "image" and
            os.path.isfile(os.path.join(self.pictures_dir, f))
        ]
        for f in files:
            os.remove(os.path.join(self.pictures_dir, f))

        # Wait for the camera to have finished focusing
        # (the exposure button gets enabled when ready)
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))
        self.assertThat(exposure_button.width, Eventually(NotEquals(0)))
        self.assertThat(exposure_button.height, Eventually(NotEquals(0)))

        # Now take the picture! (Give it a little time to animate)
        self.pointing_device.move_to_object(exposure_button)
        self.pointing_device.click()

        # Check that only one picture with the right name pattern
        # is actually there
        one_picture_on_disk = False
        for i in range(0, 10):
            files = [
                f for f in os.listdir(self.pictures_dir)
                if f[0:5] == "image" and
                os.path.isfile(os.path.join(self.pictures_dir, f))
            ]
            if len(files) == 1:
                one_picture_on_disk = True
                break
            time.sleep(1)
        self.assertEquals(one_picture_on_disk, True)

        # check that the camera is able to capture another photo
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))

    """Test taking a picture with a timer set"""
    def test_take_picture_with_timer(self):
        delay = 5
        self.enable_timer("%s seconds" % str(delay))

        # start timed shoot
        shoot_button = self.main_window.get_exposure_button()
        self.assertThat(shoot_button.enabled, Eventually(Equals(True)))
        self.pointing_device.move_to_object(shoot_button)
        self.pointing_device.click()

        switch_cameras_button = self.main_window.get_swap_camera_button()
        record_mode_button = self.main_window.get_record_control()
        view_switcher = self.main_window.get_view_switcher()

        # controls and navigation should be disabled at this point
        self.assertThat(shoot_button.enabled,
                        Eventually(Equals(True)))
        self.assertThat(switch_cameras_button.enabled,
                        Eventually(Equals(True)))
        self.assertThat(record_mode_button.enabled,
                        Eventually(Equals(True)))
        self.assertThat(view_switcher.interactive,
                        Eventually(Equals(True)))

        # after the delay controls and navigation should be re-enabled
        self.assertThat(shoot_button.enabled,
                        Eventually(Equals(True), timeout=delay))
        self.assertThat(switch_cameras_button.enabled,
                        Eventually(Equals(True), timeout=delay))
        self.assertThat(record_mode_button.enabled,
                        Eventually(Equals(True), timeout=delay))
        self.assertThat(view_switcher.interactive,
                        Eventually(Equals(True), timeout=delay))

    def enable_timer(self, label_value):
        # open bottom edge
        bottom_edge = self.main_window.get_bottom_edge()
        bottom_edge.open()

        # open video resolution option value selector showing the possible
        # values
        timer_delay_button = self.main_window.get_timer_delay_button()
        self.pointing_device.move_to_object(timer_delay_button)
        self.pointing_device.click()
        option_value_selector = self.main_window.get_option_value_selector()
        self.assertThat(
            option_value_selector.visible, Eventually(Equals(True)))

        # select a 5 seconds delay
        option = self.main_window.get_option_value_button(label_value)
        self.pointing_device.move_to_object(option)
        self.pointing_device.click()

        bottom_edge.close()

    def test_record_video(self):
        """Test clicking on the record control.

        Check if the recording time appears.

        """
        # Get all the elements
        stop_watch = self.main_window.get_stop_watch()
        exposure_button = self.main_window.get_exposure_button()

        # Click the record button to toggle photo/video mode
        self.main_window.switch_recording_mode()

        # Before recording the stop watch should read zero recording time
        # and not be visible anyway.
        self.assertThat(stop_watch.opacity, Equals(0.0))
        self.assertEquals(stop_watch.label, "00:00")

        # Click the exposure button to start recording
        self.pointing_device.move_to_object(exposure_button)
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))
        self.assertThat(exposure_button.width, Eventually(NotEquals(0)))
        self.assertThat(exposure_button.height, Eventually(NotEquals(0)))
        self.pointing_device.click()

        # Record video for 2 seconds and check if the stop watch actually
        # runs and is visible.
        # Since the timer is not precise we don't check the actual time,
        # just that it is not counting zero anymore.
        self.assertThat(stop_watch.opacity, Eventually(Equals(1.0)))
        self.assertThat(stop_watch.label, Eventually(NotEquals("00:00")))

        # Now stop the video and check if everything resets itself to
        # previous states.
        self.pointing_device.click()

        self.assertThat(stop_watch.opacity, Eventually(Equals(0.0)))

        # Now start recording a second video and check if everything
        # still works
        self.pointing_device.click()

        # Is the stop watch visible and set to 00:00?
        self.assertEquals(stop_watch.label, "00:00")
        self.assertThat(stop_watch.opacity, Eventually(Equals(1.0)))

        # Record video for 2 seconds and check if the stop watch actually works
        self.assertThat(stop_watch.label, Eventually(NotEquals("00:00")))

        # Now stop the video and go back to picture mode and check if
        # everything resets itself to previous states
        self.pointing_device.click()
        self.main_window.switch_recording_mode()

        self.assertThat(stop_watch.opacity, Eventually(Equals(0.0)))

    def test_hint_after_first_picture(self):
        hint = self.main_window.get_photo_roll_hint()
        photo_button = self.main_window.get_exposure_button()

        # Wait for the camera to be ready to take a picture
        self.assertThat(photo_button.enabled, Eventually(Equals(True)))
        self.assertThat(photo_button.width, Eventually(NotEquals(0)))
        self.assertThat(photo_button.height, Eventually(NotEquals(0)))

        # Check that the photo roll hint is hidden
        self.assertEquals(hint.visible, False)

        # Take a picture
        self.pointing_device.move_to_object(photo_button)
        self.pointing_device.click()

        # Check that the photo roll hint is displayed
        # self.assertEquals(hint.visible, True)
        self.assertThat(hint.visible, Eventually(Equals(True)))

        # Swipe to photo roll
        self.main_window.swipe_to_gallery(self)
        self.main_window.swipe_to_viewfinder(self)

        # Check that the photo roll hint is hidden
        self.assertEquals(hint.visible, False)

    @unittest.skip("Disabled this test due race condition see bug 1227373")
    def test_shoot_button_disable(self):
        """Test that the shoot button gets disabled for a while then re-enabled
        after shooting"""
        exposure_button = self.main_window.get_exposure_button()

        # The focus ring should be invisible in the beginning
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))

        # Now take the picture! (Give it a little time to animate)
        self.pointing_device.move_to_object(exposure_button)
        self.pointing_device.click()

        # autopilot might check this too late, so the exposure_button.enabled
        # is True again already before the first check
        self.assertThat(exposure_button.enabled, Eventually(Equals(False)))
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))

    """Test taking pictures at various levels of quality"""
    def test_picture_quality_setting(self):
        qualities = [("Basic Quality", 60),
                     ("Normal Quality", 80),
                     ("Fine Quality", 95)]
        for quality, expectedCompression in qualities:
            self.delete_all_photos()
            self.set_compression_quality(quality)
            self.take_picture()
            picture_file = self.get_first_picture()
            compression = self.get_compression_quality(picture_file)
            self.assertThat(compression, Equals(expectedCompression))
            self.dismiss_first_photo_hint()

    def delete_all_photos(self):
        picture_files = os.listdir(self.pictures_dir)
        for f in picture_files:
            f = os.path.join(self.pictures_dir, f)
            if os.path.isfile(f):
                os.remove(os.path.join(self.pictures_dir, f))

    def get_first_picture(self, timeout=10):
        pictures = []
        for i in range(0, timeout):
            pictures = glob.glob(os.path.join(self.pictures_dir, "*.jpg"))
            if len(pictures) != 0:
                break
            time.sleep(1)

        picture_file = os.path.join(self.pictures_dir, pictures[0])
        return picture_file

    def take_picture(self):
        exposure_button = self.main_window.get_exposure_button()

        # Wait for the camera to have finished focusing
        # (the exposure button gets enabled when ready)
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))
        self.assertThat(exposure_button.width, Eventually(NotEquals(0)))
        self.assertThat(exposure_button.height, Eventually(NotEquals(0)))

        # Press the shoot a picture button
        self.pointing_device.move_to_object(exposure_button)
        self.pointing_device.click()

    def get_compression_quality(self, picture_file):
        quality = 0
        with Image(filename=picture_file) as image:
            quality = image.compression_quality
        return quality

    def dismiss_first_photo_hint(self):
        photo_roll_hint = self.main_window.get_photo_roll_hint()
        if photo_roll_hint.enabled:
            # Swipe to photo roll and back to viewfinder
            self.main_window.swipe_to_gallery(self)
            self.main_window.swipe_to_viewfinder(self)

    def set_compression_quality(self, quality="Normal Quality"):
        # open bottom edge
        bottom_edge = self.main_window.get_bottom_edge()
        bottom_edge.open()

        # open encoding quality option value selector showing the possible
        # values
        encoding_quality_button = (
            self.main_window.get_encoding_quality_button())
        self.pointing_device.move_to_object(encoding_quality_button)
        self.pointing_device.click()
        option_value_selector = self.main_window.get_option_value_selector()
        self.assertThat(
            option_value_selector.visible, Eventually(Equals(True)))

        # tap on chosen compression quality option
        option = self.main_window.get_option_value_button(quality)
        self.pointing_device.move_to_object(option)
        self.pointing_device.click()

        bottom_edge.close()

    """Test recording videos at a set resolution and switching cameras"""
    def test_video_resolution_setting_switching_cameras(self):
        # switch to video recording and empty video folder
        self.main_window.switch_recording_mode()
        self.delete_all_videos()

        # select the first resolution for the current camera
        resolutions = self.get_available_video_resolutions()
        initial_resolution = resolutions[0]
        self.set_video_resolution(initial_resolution)

        # switch cameras and select the last resolution for the current camera
        self.main_window.switch_cameras()
        resolutions = self.get_available_video_resolutions()
        if len(resolutions) > 1:
            expected_resolution = resolutions[-1]
            self.assertThat(expected_resolution, NotEquals(initial_resolution))
            self.set_video_resolution(expected_resolution)

        # switch back to the initial camera and record a video
        self.main_window.switch_cameras()
        self.record_video(2)
        video_file = self.get_first_video()
        height = self.read_video_height(video_file)
        expected_resolution = self.get_selected_video_resolution()
        expected_height = self.height_from_resolution_label(
            expected_resolution)
        self.assertThat(height, Equals(expected_height))

    """Test recording videos at various resolutions"""
    def test_video_resolution_setting(self):
        self.main_window.switch_recording_mode()
        resolutions = self.get_available_video_resolutions()

        for resolution_label in resolutions:
            self.delete_all_videos()
            self.set_video_resolution(resolution_label)
            self.record_video(2)
            video_file = self.get_first_video()
            height = self.read_video_height(video_file)
            expected_height = self.height_from_resolution_label(
                resolution_label)
            self.assertThat(height, Equals(expected_height))
            self.dismiss_first_photo_hint()

    def get_available_video_resolutions(self):
        # open bottom edge
        bottom_edge = self.main_window.get_bottom_edge()
        bottom_edge.open()

        # open video resolution option value selector showing the possible
        # values
        video_resolution_button = (
            self.main_window.get_video_resolution_button())
        self.pointing_device.move_to_object(video_resolution_button)
        self.pointing_device.click()
        option_value_selector = self.main_window.get_option_value_selector()
        self.assertThat(
            option_value_selector.visible, Eventually(Equals(True)))
        optionButtons = option_value_selector.select_many("OptionValueButton")
        resolutions = [button.label for button in optionButtons]

        bottom_edge.close()
        return resolutions

    def get_selected_video_resolution(self):
        # open bottom edge
        bottom_edge = self.main_window.get_bottom_edge()
        bottom_edge.open()

        # open video resolution option value selector showing the possible
        # values
        video_resolution_button = (
            self.main_window.get_video_resolution_button())
        self.pointing_device.move_to_object(video_resolution_button)
        self.pointing_device.click()
        option_value_selector = self.main_window.get_option_value_selector()
        self.assertThat(
            option_value_selector.visible, Eventually(Equals(True)))
        optionButtons = option_value_selector.select_many("OptionValueButton")
        resolutions = [button.label for button in optionButtons
                       if button.selected]

        bottom_edge.close()
        return resolutions[0]

    def delete_all_videos(self):
        video_files = os.listdir(self.videos_dir)
        for f in video_files:
            os.remove(os.path.join(self.videos_dir, f))

    def set_video_resolution(self, resolution_label="720p"):
        # open bottom edge
        bottom_edge = self.main_window.get_bottom_edge()
        bottom_edge.open()

        # open video resolution option value selector showing the possible
        # values
        video_resolution_button = (
            self.main_window.get_video_resolution_button())
        self.pointing_device.move_to_object(video_resolution_button)
        self.pointing_device.click()
        option_value_selector = self.main_window.get_option_value_selector()
        self.assertThat(
            option_value_selector.visible, Eventually(Equals(True)))

        # tap on chosen video resolution option
        option = self.main_window.get_option_value_button(resolution_label)
        self.pointing_device.move_to_object(option)
        self.pointing_device.click()

        bottom_edge.close()

    def record_video(self, duration):
        exposure_button = self.main_window.get_exposure_button()

        # Click the exposure button to start recording
        self.pointing_device.move_to_object(exposure_button)
        self.assertThat(exposure_button.enabled, Eventually(Equals(True)))
        self.assertThat(exposure_button.width, Eventually(NotEquals(0)))
        self.assertThat(exposure_button.height, Eventually(NotEquals(0)))
        self.pointing_device.click()

        # Record video for duration seconds
        time.sleep(duration)
        self.pointing_device.click()

        stop_watch = self.main_window.get_stop_watch()
        self.assertThat(stop_watch.opacity, Eventually(Equals(0.0)))

    def get_first_video(self, timeout=10):
        videos = []
        for i in range(0, timeout):
            videos = os.listdir(self.videos_dir)
            if len(videos) != 0:
                break
            time.sleep(1)

        video_file = os.path.join(self.videos_dir, videos[0])
        return video_file

    def read_video_height(self, video_file):
        MI = MediaInfo()
        MI.Open(video_file)
        height = MI.Get(Stream.Video, 0, "Height")
        MI.Close()
        return height

    def height_from_resolution_label(self, resolution_label):
        # remove last character from label (always 'p')
        return resolution_label[:-1]
