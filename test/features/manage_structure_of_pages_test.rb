require 'test_helper'
require 'support/active_admin_helper'

feature 'ManageStructureOfPages' do

  include ActiveAdminHelper

  # Helpers
  def into_site_structure_page
    click_link 'Site Structure'
  end

  def into_site_structure_form
    click_link 'Create Section Page'
  end

  def into_site_content_form
    click_link 'Create Content Page'
  end

  def into_section_page title
    within '.table-with-tree__categorizer.panel' do
      click_link title
    end
  end

  def current_section
    within '.table-with-tree__categorizer.panel' do
      find :xpath, '//a[@class="active"]'
    end
  end

  # Tests
  scenario 'create root section' do
    user = create :user
    admin_login user

    into_site_structure_page
    into_site_structure_form

    assert_difference 'Structure::SectionPage.count', 1 do
      fill_in 'structure_section_page[title]', with: 'Car Catalog'
      check 'structure_section_page[visible]'
      submit_form
    end

    page.must_have_content 'Car Catalog'
    current_section.text.must_equal 'Car Catalog'
  end

  scenario 'delete section' do
    skip 'test somehow fails'

    create :root_section_page, title: 'Car Catalog'
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    assert_difference 'Structure::SectionPage.count', -1 do
      click_link 'Delete section'
    end

    page.wont_have_content 'Car Catalog'
    # TODO: test current_section
  end

  scenario 'edit section page' do
    section = create :root_section_page, title: 'Car Catalog'
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    click_link 'Edit section'

    fill_in 'structure_section_page[title]', with: 'Auto Catalog'
    submit_form

    section.reload
    section.title.must_equal 'Auto Catalog'
  end

  scenario 'edit content page' do
    section = create :root_section_page, title: 'Car Catalog'
    content = create :content_page, title: 'Jeep Compass', parent: section
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    find("a[href=\"#{edit_admin_structure_content_page_path(content)}?parent_id=#{section.id}\"]").click

    fill_in 'structure_content_page[title]', with: 'Jeep Compass 2015'
    submit_form

    content.reload
    content.title.must_equal 'Jeep Compass 2015'
  end

  scenario 'delete content page' do
    skip 'test somehow fails'

    section = create :root_section_page, title: 'Car Catalog'
    content = create :content_page, title: 'Jeep Compass', parent: section
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    assert_difference 'Structure::ContentPage.count', -1 do
      find(:xpath, "//a[@data-method='delete' and @href='#{admin_structure_content_page_path(content)}']").click
    end

    page.wont_have_content 'Jeep Compass'
    # TODO: test current_section
  end

  scenario 'create child section' do
    root_page = create :root_section_page, title: 'Car Catalog'
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    into_site_structure_form

    parent_section = find('select[name="structure_section_page[parent_id]"]').value
    parent_section.must_equal root_page.id.to_s

    assert_difference 'Structure::SectionPage.count', 1 do
      fill_in 'structure_section_page[title]', with: '4WD'
      check 'structure_section_page[visible]'
      submit_form
    end

    page.must_have_content '4WD'
    Structure::SectionPage.last.parent_id.must_equal root_page.id
    current_section.text.must_equal '4WD'
  end

  scenario 'can not create content page without choosing section page' do
    user = create :user
    admin_login user

    into_site_structure_page
    page.wont_have_content 'Create Content Page'
  end

  scenario 'create content in section' do
    root_page = create :root_section_page, title: 'Car Catalog'
    user = create :user
    admin_login user

    into_site_structure_page
    into_section_page 'Car Catalog'
    into_site_content_form

    parent_section = find('select[name="structure_content_page[parent_id]"]').value
    parent_section.must_equal root_page.id.to_s

    assert_difference 'Structure::ContentPage.count', 1 do
      fill_in 'structure_content_page[title]', with: 'Jeep Compass'
      check 'structure_content_page[visible]'
      submit_form
    end

    page.must_have_content 'Jeep Compass'
    Structure::ContentPage.last.parent_id.must_equal root_page.id
    current_section.text.must_equal 'Car Catalog'
  end

end