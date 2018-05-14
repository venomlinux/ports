#!/usr/bin/env python

# Crunchbang Openbox Logout
#   - GTK/Cairo based logout box styled for Crunchbang
#
#    Andrew Williams <andy@tensixtyone.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

import logging
import os
import dbus

class DbusController (object):

    """ DbusController handles all DBus actions required by OBLogout and acts
        as a middle layer between the application and Dbus"""

    @property
    def _sysbus (self):
        """System DBus"""
        if not hasattr (DbusController, "__sysbus"):
            DbusController.__sysbus = dbus.SystemBus ()
        return DbusController.__sysbus

    @property
    def _sessbus (self):
        """Session DBus"""
        if not hasattr (DbusController, "__sessbus"):
            DbusController.__sessbus = dbus.SessionBus ()
        return DbusController.__sessbus

    @property
    def _polkit (self):
        """PolicyKit object"""
        if not hasattr (DbusController, "__polkit"):
            pk = self._sysbus.get_object ("org.freedesktop.PolicyKit", "/")
            DbusController.__polkit = dbus.Interface(pk, 'org.freedesktop.PolicyKit')
        return DbusController.__polkit

    @property
    def _halpm (self):
        """HAL controller object""" 
        if not hasattr (DbusController, "__halpm"):
            hal = self._sysbus.get_object ("org.freedesktop.Hal", "/org/freedesktop/Hal/devices/computer")
            DbusController.__halpm  = dbus.Interface(hal, "org.freedesktop.Hal.Device.SystemPowerManagement")
        return DbusController.__halpm

    @property
    def _authagent (self):
        """AuthenticationAgent object"""
        if not hasattr (DbusController, "__authagent"):
            autha = self._sessbus.get_object ("org.freedesktop.PolicyKit.AuthenticationAgent", "/", "org.gnome.PolicyKit.AuthorizationManager.SingleInstance")
            DbusController.__authagent = dbus.Interface(autha,'org.freedesktop.PolicyKit.AuthenticationAgent')

        return DbusController.__authagent

    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)

    def __check_perms(self, id):   
        """ Check if we have permissions for a action """

        self.logger.debug('Checking permissions for %s' % id)

        #try:
        res = self._polkit.IsProcessAuthorized(id, os.getpid(), False)
        #except:
        #    return False

        if res == "yes":
            self.logger.debug("Authorised to use %s, res = %s" % (id, res))
            return True
        else:
            self.logger.debug("Not authorised to use, requires %s" % res)
            return False

    def __auth_perms(self, id):   
        """ Check if we have permissions for a action, if not, try to obtain them via PolicyKit """
     
        if self.__check_perms(id):
            return True
        else: 

            self.logger.debug('Attempting to obtain %s' % id)
            grant = self._authagent.ObtainAuthorization(id, 0, os.getpid(), timeout=300, dbus_interface = "org.freedesktop.PolicyKit.AuthenticationAgent")
            self.logger.debug("Result: %s" % bool(grant))

            return self.__check_perms(id)
            #return bool(grant)

    def __get_sessions(self):
        """ Using DBus and ConsoleKit, get the number of sessions. This is used by PolicyKit to dictate the 
            multiple sessions permissions for the various reboot/shutdown commands """

        # Check the number of active sessions
        manager_obj = dbus.SystemBus().get_object ('org.freedesktop.ConsoleKit', '/org/freedesktop/ConsoleKit/Manager')
        manager = dbus.Interface (manager_obj, 'org.freedesktop.ConsoleKit.Manager')

        cnt = 0
        seats = manager.GetSeats ()
        for sid in seats:
            seat_obj = dbus.SystemBus().get_object ('org.freedesktop.ConsoleKit', sid)
            seat = dbus.Interface (seat_obj, 'org.freedesktop.ConsoleKit.Seat')
            cnt += len(seat.GetSessions())

        return cnt


    def check_ability(self, action):
        """Check if HAL can complete action type requests, for example, suspend, hiberate, and safesuspend"""

        if action == 'suspend':
            return self._halpm.CanSuspend
        elif action == 'hibernate':
            return self._halpm.CanHibernate
        elif action == 'safesuspend':
             if not self._halpm.CanHibernate or not pm.CanSuspend:
                return False

        return True

    def restart(self):
        """Restart the system via HAL, if we do not have permissions to do so obtain them via PolicyKit"""

        if self.__get_sessions() > 1:
            if not self.__auth_perms("org.freedesktop.hal.power-management.reboot-multiple-sessions"):
                return False
        else:
            if not self.__auth_perms("org.freedesktop.hal.power-management.reboot"):
                return False

        self.logger.debug("Rebooting...")
        return self._halpm.Reboot()

    def shutdown(self):
        """Shutdown the system via HAL, if we do not have permissions to do so obtain them via PolicyKit"""

        if self.__get_sessions() > 1:
            if not self.__auth_perms("org.freedesktop.hal.power-management.shutdown-multiple-sessions"):
                return False
        else:
            if not self.__auth_perms("org.freedesktop.hal.power-management.shutdown"):
                return False            

        return self._halpm.Shutdown()

    def suspend(self):
        if not self.__auth_perms("org.freedesktop.hal.power-management.suspend"):
            return False            
        else:
            return self._halpm.Suspend()

    def hibernate(self):
        if not self.__auth_perms("org.freedesktop.hal.power-management.hibernate"):
            return False            
        else:
            return self._halpm.Hibernate()

    def safesuspend(self):
        pass

if __name__ == "__main__":

    logging.basicConfig(level=logging.DEBUG)

    t = DbusController()
    print t.restart()



