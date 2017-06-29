module ApplicationHelper

  # ページ毎の body のID属性を返す
  def page_classes
    return [controller_name, action_name]
      .join("-")
      .gsub("-", "_")
      .gsub("/", "_")
  end

  #
  # API のレスポンスからページネーションを表示する
  #
  def api_paginate(response, url)
    page = response.pagination
    queries = []

    html = content_tag(:ul, class: "pagination center") do
      inner_html = ''

      if page.current_page != 1
        inner_html += content_tag(:li) do
          link_to request.query_parameters.merge(page:  1) do
            content_tag(:i, 'chevron_left', class: "material-icons")
          end
        end
      end

      start_num = page.current_page - 5
      end_num = page.current_page + 5

      (start_num..end_num).each do |num|
        if num >= 1 && num <= page.total_page
          if num != page.current_page
            href = request.query_parameters.merge(page:  num)
            klass = ''
          else
            href = '#'
            klass = 'active'
          end
          inner_html += content_tag(:li, class: klass) do
            link_to num, href
          end
        end
      end

      if page.current_page != page.total_page
        inner_html += content_tag(:li) do
          link_to request.query_parameters.merge(page:  page.total_page) do
            content_tag(:i, 'chevron_right', class: "material-icons")
          end
        end
      end

      inner_html.html_safe
    end

    return html
  end

  # 年代を表示
  def display_age_of(archive)
    start_date = change_text_from(archive.created_begin_on)
    end_date = change_text_from(archive.created_end_on)
    if start_date && end_date
      return "#{start_date} - #{end_date}"
    elsif start_date
      return start_date
    else
      return '不詳'
    end
  end

  # 日付をテキストで返却
  def change_text_from(date)
    if date.year.present?
      date_text = []
      date_text << "#{date.year}年"if date.year != 0
      date_text << "#{date.month}月"if date.month != 0
      date_text << "#{date.day}日"if date.day != 0
      return date_text.join
    else
      return nil
    end
  end

  # 資料名称＋年代のテキストを返す
  def name_with_created_on(archive)
    start_date = change_text_from(archive.created_begin_on)
    end_date = change_text_from(archive.created_end_on)
    if start_date && end_date
      return "#{archive.name}（#{start_date} - #{end_date}）"
    elsif start_date
      return "#{archive.name}（#{start_date}）"
    else
      return archive.name
    end
  end

end
