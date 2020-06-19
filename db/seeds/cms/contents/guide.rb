puts "# guide"

def save_guide_column(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }
  item = Guide::Column.find_or_initialize_by(cond)
  item.attributes = data
  item.save

  item
end

def save_guide_procedure(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }
  item = Guide::Procedure.find_or_initialize_by(cond)
  item.attributes = data
  item.save

  item
end

save_guide_column name: "日本国外からの転入", question: "日本国外から転入する方がいる", order: 10
save_guide_column name: "国民年金への新規加入", question: "国民年金に新たに加入する方がいる", order: 20

array = Guide::Column.where(site_id: @site._id).map { |m| [m.name, m] }
guide_columns = Hash[*array.flatten]

save_guide_procedure name: "転入届", html: "<p>転入届が必要です。</p>", order: 10,
                     not_applicable_column_ids: [guide_columns['日本国外からの転入'].id]
save_guide_procedure name: "国外からの転入届", html: "<p>国外からの転入届が必要です。</p>", order: 20,
                     applicable_column_ids: [guide_columns['日本国外からの転入'].id]
save_guide_procedure name: "国民年金の資格取得", html: "<p>国民年金の資格取得が必要です。</p>", order: 30,
                     applicable_column_ids: [guide_columns['国民年金への新規加入'].id]

array = Guide::Procedure.where(site_id: @site._id).map { |m| [m.name, m] }
guide_procedures = Hash[*array.flatten]

save_node route: "guide/node", filename: "procedure", name: "目的別ガイド", layout_id: @layouts["one"].id,
          guide_index_html: '<p>必要な手続きを確認します。</p>', guide_html: '<p>次の項目に該当しますか。</p>',
          procedure_ids: [
            guide_procedures['転入届'].id, guide_procedures['国外からの転入届'].id, guide_procedures['国民年金の資格取得'].id
          ]
