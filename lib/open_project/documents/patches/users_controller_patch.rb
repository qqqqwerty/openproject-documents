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
    module UsersControllerPatch

      def self.included(base) # :nodoc:
        base.class_eval do
          verify method: :put, only: :update_documents_params, render: { nothing: true, status: :method_not_allowed }
          include InstanceMethods
        end
      end

      module InstanceMethods
        def update_documents_params
          if params[:id].present?
            @user = User.find(params[:id].to_i)
          else
            render :status => 404           
          end
          pref_params = if params[:pref].present?
                          permitted_params.pref_of_documents
                        else
                          {}
                        end
          if @user.save

            @user.pref.attributes = pref_params
            @user.pref.save

            respond_to do |format|
              format.html do
                flash[:notice] = l(:notice_successful_update)
                redirect_back(fallback_location: edit_user_path(@user))
              end
            end
          else
            @auth_sources = AuthSource.all
            @membership ||= Member.new
            # Clear password input
            @user.password = @user.password_confirmation = nil

            respond_to do |format|
              format.html do
                render action: :edit
              end
            end
          end
        rescue ::ActionController::RedirectBackError
          redirect_to controller: '/users', action: 'edit', id: @user
        end
      end
    end
  end
end
