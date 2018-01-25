#-- encoding: UTF-8
#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class DocumentsController < ApplicationController
  include PaginationHelper
  default_search_scope :documents
  model_object Document
  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_model_object, except: [:index, :indexall, :new, :create]
  before_action :find_project_from_association, except: [:index, :indexall, :new, :create]
  before_action :authorize, except: [:indexall]
  before_action :require_admin, only: [:indexall]


  def index
    @display_attachments = User.current.pref.display_attachments_preference?
    @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'
    documents = @project.documents
    case @sort_by
    when 'date'
      @grouped = documents.group_by {|d| d.updated_on.to_date }
    when 'title'
      @grouped = documents.group_by {|d| d.title.first.upcase}
    when 'author'
      @grouped = documents.with_attachments.group_by {|d| d.attachments.last.author}
    else
      @grouped = documents.includes(:category).group_by(&:category)
    end
    render layout: false if request.xhr?
  end
  
  def indexall
    @display_attachments = User.current.pref.display_attachments_preference?
    @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'
    @documents = nil
    case @sort_by
    when 'date'
      @documents = Document.with_attachments_sorted('COALESCE(updated_on, documents.created_on)')
                            .page(page_param)
                            .per_page(per_page_param)
      @grouped = @documents.group_by {|d| d.updated_on.to_date }
    when 'title'
      @documents = Document.with_attachments_sorted('title')
                            .page(page_param)
                            .per_page(per_page_param)
      @grouped = @documents.group_by {|d| d.title.first.upcase}
    when 'author'
      @documents = Document.with_attachments_sorted('author_id')
                            .with_attachments
                            .page(page_param)
                            .per_page(per_page_param)
      @grouped = @documents.group_by {|d| d.attachments.last.author}
    else
      @documents = Document.with_categories_sorted('position')
                            .page(page_param)
                            .per_page(per_page_param)
      @grouped = @documents.includes(:category).group_by(&:category)
    end
    render layout: false if request.xhr?
  end

  def show
    @attachments = @document.attachments.order('created_on DESC')
  end

  def new
    @document = @project.documents.build
    @document.attributes = document_params
  end

  def create
    @document = @project.documents.build
    @document.attributes = document_params
    if @document.save
      Attachment.attach_files(@document, collect_attachments_info)
      render_attachment_warning_if_needed(@document)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_documents_path(@project)
    else
      render action: 'new'
    end
  end

  def edit
    @categories = DocumentCategory.all
  end

  def update
    @document.attributes = document_params
    if @document.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @document
    else
      render action: 'edit'
    end
  end

  def destroy
    @document.destroy
    redirect_to controller: '/documents', action: 'index', project_id: @project
  end

  def add_attachment
    attachments = Attachment.attach_files(@document, collect_attachments_info)
    render_attachment_warning_if_needed(@document)

    if attachments.present? && attachments[:files].present? && Setting.notified_events.include?('document_added')
      users = attachments[:files].first.container.recipients
      users.each do |user|
        UserMailer.attachments_added(user, attachments[:files]).deliver
      end
    end
    redirect_to action: 'show', id: @document
  end

  private

  def document_params
    params.fetch(:document, {}).permit('category_id', 'title', 'description')
  end
  
  def collect_attachments_info
    form_attachments = {}
    if (params[:multiple_attachments] != nil)
      size = params[:multiple_attachments].length
      i = 0;
      number_of_descriptions = params[:attachments].length
      params[:multiple_attachments].each do |file|
        if (i+1 > number_of_descriptions || i >= 10)
          break;
        end
        form_attachments[i] = {}
        form_attachments[i]['file'] = file
        form_attachments[i]['description'] = params[:attachments][(i+1).to_s][:description]
        i = i + 1
      end
    else
      form_attachments = params[:attachments]
    end
    form_attachments
  end
end
