# OpenProject Local Avatars plugin
#
# Copyright (C) 2010  Andrew Chaika, Luca Pireddu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module OpenProject::Documents
  module Patches
    module MyControllerPatch

      def self.included(base) # :nodoc:
        base.class_eval do
          menu_item :documents_settings,            only: [:documents_settings]
          include InstanceMethods
        end
      end

      module InstanceMethods
        def documents_settings
          @user = User.current
          write_documents_settings(redirect_to: :documents_settings)
        end
        
        private
        
        def write_documents_settings(redirect_to:)
          if request.patch?
            @user.pref.attributes = if params[:pref].present?
                                      permitted_params.pref_of_documents
                                    else
                                      {}
                                    end
            if @user.save
              @user.pref.save
              flash[:notice] = l(:notice_account_updated)
              redirect_to(action: redirect_to)
            end
          end
        end
      end
    end
  end
end
