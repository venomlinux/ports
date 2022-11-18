 #################################################################################################################
 #
 #    Copyright (C) 2013-2020 MulticoreWare, Inc
 #
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 #
 # This program is also available under a commercial proprietary license.
 # For more information, contact us at license @ x265.com
 #
 # Authors: Janani T.E <janani.te@multicorewareinc.com>, Srikanth Kurapati <srikanthkurapati@multicorewareinc.com>
 #
 #################################################################################################################
 # PURPOSE: Identity version control software version display, also read version files to present x265 version.
 #################################################################################################################
 #Default Settings, for user to be vigilant about x265 version being reported during product build.
set(X265_VERSION "@@VERSION@@_Release")
set(X265_LATEST_TAG "@@VERSION@@")
set(X265_TAG_DISTANCE "1")

#will always be printed in its entirety based on version file configuration to avail revision monitoring by repo owners
message(STATUS "X265 RELEASE VERSION ${X265_VERSION}")
