#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'digest/sha2'

# This module contains functions for hashing passwords from the
# Candlepin DB
module Password

  # Checks the password against the stored password
  def Password.check(password, store)
    if self.hash(password, Password.salt) == store
      true
    else
      false
    end
  end

  protected

  def Password.salt
    "b669e3274a43f20769d3dedf03e9ac180e160f92"
  end

  def Password.hash(password, salt)
    digest = "#{salt}#{password}"
    digest = Digest::SHA1.hexdigest(digest) 
    digest
  end

end
