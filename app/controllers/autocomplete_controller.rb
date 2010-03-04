class AutocompleteController < ApplicationController

  def render_output(result_strings)
    @results = result_strings
    render :inline  => @results.length > 0 ? "<ul><%= @results.map {|string| '<li>' + string + '</li>'} -%></ul>" : ""
  end

  # works for any tag class where what you want to return are the names
  def tag_finder(tag_class, search_param)
    if search_param
      render_output(tag_class.canonical.find(:all, :order => :name, :conditions => ["name LIKE ?", '%' + search_param + '%'], :limit => 10).map(&:name))
    end
  end
  
  # works for any tag class where what you want to return are the names
  def noncanonical_tag_finder(tag_class, search_param)
    if search_param
      render_output(tag_class.find(:all, :order => :name, :conditions => ["canonical = 0 AND name LIKE ?", '%' + search_param + '%'], :limit => 10).map(&:name))
    end
  end

  def pseud_finder(search_param)
    if search_param
      render_output(Pseud.find(:all, :order => :name, :conditions => ["name LIKE ?", '%' + search_param + '%'], :limit => 10).map(&:byline))
    end
  end
  
  def collection_finder(search_param)
    render_output(Collection.open.with_name_like(search_param).name_only.map(&:name).sort)
  end

  ###### all the field-specific methods go here 
  
  # pseud-finder methods -- to add a new one, just put the name of the field into the 
  # %w list
  %w(work_recipients participants_to_invite pseud_byline).each do |field|
    define_method("#{field}") do
      pseud_finder(params[params[:fieldname]])
    end
  end
  
  # to handle the autocomplete requests for each type from the nested prompt form, using define_method to set up all
  # the different tag types
  %w(rating category warning).each do |tag_type| 
    define_method("canonical_#{tag_type}_finder") do
      tag_finder("#{tag_type}".classify.constantize, params[params[:fieldname]])
    end
  end 

  # generic canonical tag finders
  %w(canonical_tag_finder tag_string).each do |field|
    define_method("#{field}") do
      tag_finder(Tag, params[params[:fieldname]])
    end
  end

  # fandom finders
  %w(canonical_fandom_finder fandom_string work_fandom tag_fandom_string collection_filters_fandom bookmark_external_fandom_string ).each do |field|
    define_method("#{field}") do
      tag_finder(Fandom, params[params[:fieldname]])
    end
  end

  # pairing finders
  %w(canonical_pairing_finder work_pairing tag_pairing_string bookmark_external_pairing_string).each do |field|
    define_method("#{field}") do
      tag_finder(Pairing, params[params[:fieldname]]) 
    end
  end

  # character finders
  %w(canonical_character_finder character_string work_character tag_character_string bookmark_external_character_string).each do |field|
    define_method("#{field}") do
      tag_finder(Character, params[params[:fieldname]])
    end
  end

  # freeform finders
  %w(canonical_freeform_finder work_freeform tag_freeform_string).each do |field|
    define_method("#{field}") do
      tag_finder(Freeform, params[params[:fieldname]])
    end
  end  
  
  # collection name finders
  %w(collection_names work_collection_names).each do |field|
    define_method("#{field}") do
      collection_finder(params[params[:fieldname]])
    end
  end

  def collection_parent_name
    render_output(current_user.maintained_collections.top_level.with_name_like(params[:collection_parent_name]).name_only.map(&:name).sort)
  end

  def collection_filters_title
    render_output(Collection.find(:all, :conditions => ["parent_id IS NULL AND title LIKE ?", params[:collection_filters_title] + '%'], :limit => 10, :order => :title).map(&:title))    
  end

  # tag wrangling finders
  def tag_syn_string
    tag_finder(params[:type].constantize, params[:tag_syn_string])
  end

  def tag_merger_string
    noncanonical_tag_finder(params[:type].constantize, params[:tag_merger_string])
  end
  
  def tag_media_string
    tag_finder(Media, params[:tag_media_string])
  end 
  
  def tag_meta_tag_string
    tag_finder(params[:type].constantize, params[:tag_meta_tag_string])
  end
  
  def tag_sub_tag_string
    tag_finder(params[:type].constantize, params[:tag_sub_tag_string])
  end   

  
end
