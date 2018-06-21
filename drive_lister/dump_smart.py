#!/usr/bin/env python3

"""
/*
 * Copyright (C) 2018 Erik Mossberg
 *
 * This file is part of DriveLister.
 *
 * DriveLister is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * DriveList is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
"""

import os
import re
import subprocess
import datetime

class Device(object):
    def __init__(self, abspath):
        """
        abspath - Absolute path to a block device. Passing MD/Raid/loop devices in here is dragons.
        """
        self._abspath = abspath
        self._smartctl_output = None
        self._partlist_output = None
        self._snr = None
        self._capacity_str = None
        self._family = None

        now = datetime.datetime.now()
        self._timestamp = now.strftime("%Y-%m-%d_%H%M")


    def get_smartctl_output(self):
        """
        Raw output from smartctl.
        """
        if self._smartctl_output != None:
            return self._smartctl_output

        subp = subprocess.run(["smartctl", "-a", self._abspath], stdout=subprocess.PIPE)
        stdout = subp.stdout.decode('ascii').split("\n")

        self._smartctl_output = stdout
        return self._smartctl_output

    def get_partlist_output(self):
        """
        Raw output from partition listing. Uses gpart or parted, but 
        avoids fdisk, since the arguments differ on various os:es. Don't want to
        accidentally change anything.
        """
        if self._partlist_output != None:
            return self._partlist_output

        try:
            # BSD?
            subp = subprocess.run(["gpart", "show", self._abspath], stdout=subprocess.PIPE)
            stdout = subp.stdout.decode('ascii').split("\n")
        except Exception:
            # Linux?
            subp = subprocess.run(["parted", self._abspath, "print"], stdout=subprocess.PIPE)
            stdout = subp.stdout.decode('ascii').split("\n")


        self._partlist_output = stdout
        return self._partlist_output


    def get_snr(self):
        """
        Serial number.
        """
        if self._snr is not None:
            return self._snr

        snr = self.get_smartvalue_by_key("Serial Number:")
        self._snr = snr

        return self._snr

    def cleanup_string(self, to_clean):
        """
        Remove whitespaces etc from string.
        """
        work = to_clean.replace(" ", "_")
        work = work.replace("[", "")
        work = work.replace("]", "")
        work = work.replace("(", "")
        work = work.replace(")", "")
        work = work.replace("/", "_")
        work = work.replace(",", "_")
        return work.strip()

    def get_capacity_str(self):
        """
        Capacity string, without any whitespace.
        """

        if self._capacity_str is not None:
            return self._capacity_str

        capacity = self.get_smartvalue_by_key("User Capacity:")
        self._capacity_str = self.cleanup_string(capacity[capacity.index("["):])

        return self._capacity_str

    def get_smartvalue_by_key(self, key):
        """
        Generic smart value getter.
        """
        smartctl = self.get_smartctl_output()
        for line in smartctl:
            if line.strip().startswith(key):
                return line[line.index(":")+1:].strip()

        raise Exception("Could not find smartvalue by key '%s'" % key)

    def get_model_family(self):
        """
        Model family.
        """
        if self._family is not None:
            return self._family

        try:
            family = self.get_smartvalue_by_key("Model Family")
            family = self.cleanup_string(family)
            self._family = family

        except Exception:
            self._family = "UnknownFamily" # Happens in non-smart drives, such as virtualized ones.

        return self._family

    def gather_and_write(self):
        """
        Get all data via smartctl calls etc, then save to relevant files.
        """
        
        snr = self.get_snr()
        capacity = self.get_capacity_str()
        model = self.get_model_family()


        basename = "%s_%s_%s_%s" % (model, snr, capacity, self._timestamp)
        f = open("%s.smart" % basename, 'w')
        f.write("\n".join(self.get_smartctl_output()))
        f.close()

        f = open("%s.part" % basename, 'w')
        f.write("\n".join(self.get_partlist_output()))
        f.close()



class GatherDriveData(object):
    def __init__(self):
        """
        Not main.
        """
        pass


    def detect_drives(self):
        """
        Return abspath to drives.
        """
        contents = os.listdir('/dev')
        contents = [os.path.join("/dev/", c) for c in contents if re.match("^sd[a-z]$", c) or re.match("^ada[0-9]+$", c)]
        return contents



    def main(self):
        """
        main.
        """
        drives = self.detect_drives()

        print("Detected %d drives : %s" % (len(drives), ", ".join(drives)))

        for drive in drives:
            device = Device(drive)
            device.gather_and_write()


if __name__ == '__main__':
    gdd = GatherDriveData()
    gdd.main()
