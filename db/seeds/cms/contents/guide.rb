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
save_guide_column name: "マイナンバーカードの所持", question: "マイナンバーカードを持っている方がいる", order: 20
save_guide_column name: "住民基本台帳カードの所持", question: "住民基本台帳カードを持っている方がいる", order: 30
save_guide_column name: "運転免許証の所持", question: "運転免許証を持っている方がいる", order: 40
save_guide_column name: "マイナンバーカードまたは住民基本台帳カードで転出手続きをした",
                  question: "マイナンバーカードまたは住民基本台帳カードで転出手続きをした", order: 50
save_guide_column name: "妊娠中の方がいる", question: "妊娠中の方がいる", order: 60
save_guide_column name: "養育中の20歳未満の子どもがいる", question: "養育中の20歳未満の子どもがいる", order: 70
save_guide_column name: "年金を受給している方がいる", question: "年金を受給している方がいる", order: 80
save_guide_column name: "障害者の方がいる", question: "障害者の方がいる", order: 90
save_guide_column name: "前住所で要介護認定を受けている方がいる", question: "前住所で要介護認定を受けている方がいる", order: 100
save_guide_column name: "介護保険の負担限度額認定証の所持", question: "介護保険の負担限度額認定証を持っている", order: 110
save_guide_column name: "子どもは小学校入学前である", question: "子どもは小学校入学前である", order: 120
save_guide_column name: "子どもは小学生である", question: "子どもは小学生である", order: 130
save_guide_column name: "子どもは中学生である", question: "子どもは中学生である", order: 140
save_guide_column name: "公立小中学校に転校", question: "公立小中学校に転校する", order: 150
save_guide_column name: "保育施設への入所を希望", question: "保育施設への入所を希望する", order: 160
save_guide_column name: "幼稚園施設への入所を希望", question: "幼稚園施設への入所を希望する", order: 170
save_guide_column name: "学童保育への入所を希望", question: "学童保育への入所を希望する", order: 180
save_guide_column name: "ひとり親家庭等である", question: "ひとり親家庭等である", order: 190
save_guide_column name: "会社や事業所の社会保険に加入している方がいる",
                  question: "会社や事業所の社会保険に加入している方がいる", order: 200
save_guide_column name: "国民年金に新たに加入、または継続する方がいる",
                  question: "国民年金に新たに加入、または継続する方がいる", order: 210
save_guide_column name: "国民健康保険に加入、もしくは引続き加入する方がいる",
                  question: "国民健康保険に加入、もしくは引続き加入する方がいる", order: 220
save_guide_column name: "後期高齢者医療保険に加入している方がいる", question: "後期高齢者医療保険に加入している方がいる", order: 230
save_guide_column name: "国民健康保険に加入されている方で、70歳～74歳の方がいる",
                  question: "国民健康保険に加入されている方で、70歳～74歳の方がいる", order: 240
save_guide_column name: "後期高齢者医療保険に加入している方は県外からの転入である",
                  question: "後期高齢者医療保険に加入している方は県外からの転入である", order: 250
save_guide_column name: "特定疾病療養受療証を持っている方がいる", question: "特定疾病療養受療証を持っている方がいる", order: 260
save_guide_column name: "限度額適用認定証(または限度額適用・標準負担額減額認定証)を持っている方がいる",
                  question: "限度額適用認定証(または限度額適用・標準負担額減額認定証)を持っている方がいる", order: 270
save_guide_column name: "父または母が障害者である", question: "父または母が障害者である", order: 280
save_guide_column name: "精神障害者保健福祉手帳の所持", question: "精神障害者保健福祉手帳を持っている方がいる", order: 290
save_guide_column name: "療育手帳の所持", question: "療育手帳を持っている方がいる", order: 300
save_guide_column name: "身体障害者手帳の所持", question: "身体障害者手帳を持っている方がいる", order: 310
save_guide_column name: "特別障害者手当を受給している方がいる", question: "特別障害者手当を受給している方がいる", order: 320
save_guide_column name: "重度心身障害者医療費受給者証の所持", question: "重度心身障害者医療費受給者証を持っている方がいる", order: 330
save_guide_column name: "自立支援医療受給者証の所持", question: "自立支援医療受給者証を持っている方がいる", order: 340
save_guide_column name: "原付バイクの所持", question: "原付バイクを持っている", order: 350
save_guide_column name: "小型特殊自動車の所持", question: "小型特殊自動車を持っている", order: 360
save_guide_column name: "126～250ccのバイク（軽二輪）の所持", question: "126～250ccのバイク（軽二輪）を持っている", order: 370
save_guide_column name: "250cc超のバイク（小型二輪）の所持", question: "250cc超のバイク（小型二輪）を持っている", order: 380
save_guide_column name: "軽自動車の所持", question: "軽自動車を持っている", order: 390
save_guide_column name: "普通自動車の所持", question: "普通自動車を持っている", order: 400
save_guide_column name: "引越し前の市区町村役所で原付バイクの廃車の手続きを行っている",
                  question: "引越し前の市区町村役所で原付バイクの廃車の手続きを行っている", order: 410
save_guide_column name: "引越し前の市区町村役所で小型特殊自動車の廃車の手続きを行っている",
                  question: "引越し前の市区町村役所で小型特殊自動車の廃車の手続きを行っている", order: 420
save_guide_column name: "転入先の地域は軽自動車の保管場所届出が必要な地域である",
                  question: "転入先の地域は軽自動車の保管場所届出が必要な地域である", order: 430
save_guide_column name: "自動車の保管場所は自分の所有地である", question: "自動車の保管場所は自分の所有地である", order: 440
save_guide_column name: "土地・家屋の所有", question: "土地・家屋を所有している", order: 450
save_guide_column name: "印鑑登録", question: "印鑑登録をする", order: 460
save_guide_column name: "犬を飼っている", question: "犬を飼っている", order: 470

array = Guide::Column.where(site_id: @site._id).map { |m| [m.name, m] }
guide_columns = Hash[*array.flatten]

save_guide_procedure name: "転入届 (転出証明書による手続き)", html: "<p>転入届 (転出証明書による手続き)が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(マイナンバーカード、または住民基本台帳カード 転出証明書 本人確認書類 印鑑),
                     procedure_applicant: %w(本人),
                     order: 10,
                     not_applicable_column_ids: [guide_columns['日本国外からの転入'].id,
                                                 guide_columns['マイナンバーカードまたは住民基本台帳カードで転出手続きをした'].id]
save_guide_procedure name: "転入届 (転入届の特例による手続き)", html: "<p>転入届 (転入届の特例による手続き)が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(マイナンバーカード、または住民基本台帳カード 本人確認書類 印鑑),
                     procedure_applicant: %w(本人),
                     order: 20,
                     applicable_column_ids: [guide_columns['マイナンバーカードまたは住民基本台帳カードで転出手続きをした'].id],
                     not_applicable_column_ids: [guide_columns['日本国外からの転入'].id]
save_guide_procedure name: "転入届 (国外からの転入)", html: "<p>転入届 (国外からの転入)が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(パスポート 本人確認書類 印鑑 戸籍謄本の写し 戸籍の附票の写し 在留カード、または特別永住者証明書
                                    世帯主との家族関係がわかる証明書), procedure_applicant: %w(本人),
                     remarks: 'この手続きを行うにあたっては、はじめに窓口でご相談されることをお勧めします。',
                     order: 30, applicable_column_ids: [guide_columns['日本国外からの転入'].id]
save_guide_procedure name: "マイナンバーカードの住所変更 ", html: "<p>マイナンバーカードの住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(マイナンバーカード), procedure_applicant: %w(本人),
                     remarks: '署名用電子証明書は住所変更に伴い、自動的に失効します。
再取得を希望される場合は、本人によるお手続きが必要です。',
                     order: 40, applicable_column_ids: [guide_columns['マイナンバーカードの所持'].id]
save_guide_procedure name: "住民基本台帳カードの住所変更", html: "<p>住民基本台帳カードの住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(住民基本台帳カード), procedure_applicant: %w(本人),
                     remarks: '身分証明書としての利用は可能ですが、電子証明書の付与は平成27年末で終了しました。
署名用電子証明書が必要な場合はマイナンバーカードを取得してください。',
                     order: 50, applicable_column_ids: [guide_columns['住民基本台帳カードの所持'].id]
save_guide_procedure name: "マイナンバーカード交付申請", html: "<p>マイナンバーカード交付申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(個人番号カード交付申請書兼電子証明書発行申請書 顔写真の画像データ), procedure_applicant: %w(本人),
                     remarks: '引越し前の住所に送られてきた個人番号カード交付申請書兼電子証明書発行申請書は使用できなくなるため、
引越し先の市区町村で新しい個人番号カード交付申請書兼電子証明書発行申請書を受け取ったのちに手続きを行います。
交付申請はインターネットまたは郵送で手続きができます。',
                     order: 60, applicable_column_ids: [guide_columns['住民基本台帳カードの所持'].id]
save_guide_procedure name: "国民健康保険の加入届", html: "<p>国民健康保険の加入届が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(マイナンバー確認書類 本人確認書類 印鑑 口座番号確認書類 口座届出印),
                     procedure_applicant: %w(本人),
                     remarks: '国民健康保険への加入は市区町村ごとに行う必要があるため、引越し先の市区町村役所で加入の手続きが必要です。',
                     order: 70, applicable_column_ids: []
save_guide_procedure name: "後期高齢者医療保険の加入届 (県外からの転入)",
                     html: "<p>後期高齢者医療保険の加入届 (県外からの転入)が必要です。</p>", procedure_location: '市区町村役所',
                     belongings: %w(マイナンバー確認書類 負担区分証明書 本人確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 80, applicable_column_ids: []
save_guide_procedure name: "国民年金の被保険者住所変更届", html: "<p>国民年金の被保険者住所変更届が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(年金手帳 印鑑), procedure_applicant: %w(本人),
                     remarks: '国民年金に加入している方は、住所変更の手続きが必要です。
ただし、マイナンバーと基礎年金番号が紐づいている方は手続きが不要となります。',
                     order: 90, applicable_column_ids: []
save_guide_procedure name: "妊婦健康診査受診票の交付申請", html: "<p>妊婦健康診査受診票の交付申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(母子健康手帳 妊婦健康診査受診票の未使用分), procedure_applicant: %w(本人),
                     remarks: '妊婦健康診査の費用を助成する各自治体の制度を利用するための申請です。',
                     order: 100, applicable_column_ids: [guide_columns['妊娠中の方がいる'].id]
save_guide_procedure name: "児童手当の受給申請", html: "<p>児童手当の受給申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(印鑑 口座番号確認書類 健康保険証、または年金加入証明書 (厚生年金・各種共済に加入の場合)
                                    マイナンバー確認書類 本人確認書類), procedure_applicant: %w(本人),
                     remarks: '０歳児から中学生までの子どもがいるすべての家庭に給付される児童手当の受給申請です。',
                     order: 110, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "子ども医療費助成の申請", html: "<p>子ども医療費助成の申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(子どもの健康保険証 本人確認書類 マイナンバー確認書類 印鑑 所得課税証明書 口座番号確認書類),
                     procedure_applicant: %w(本人),
                     remarks: '子ども医療費助成の制度が各市区町村にて用意されています。 引越し先の市区町村役所で手続きが必要です。',
                     order: 120, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "転入学通知書の取得申請", html: "<p>転入学通知書の取得申請が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(在学証明書), procedure_applicant: %w(本人),
                     remarks: '公立の小中学校に通われているお子さんについては、転校先の小中学校に提出する転入学通知書を、
引越し先の市区町村役所で取得する必要があります。',
                     order: 130, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "保育所に関する手続き", html: "<p>保育所に関する手続きが必要です。</p>",
                     procedure_location: '市区町村役所', procedure_applicant: %w(本人),
                     remarks: 'この手続きを行うにあたっては、はじめに窓口でご相談されることをお勧めします。',
                     order: 140,
                     applicable_column_ids: [
                       guide_columns['養育中の20歳未満の子どもがいる'].id, guide_columns['子どもは小学校入学前である'].id
                     ]
save_guide_procedure name: "学童保育の手続き", html: "<p>学童保育の手続きが必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(印鑑（スタンプ印不可） 入所申込書),
                     procedure_applicant: %w(本人), order: 150,
                     applicable_column_ids: [
                       guide_columns['養育中の20歳未満の子どもがいる'].id, guide_columns['子どもは小学生である'].id
                     ]
save_guide_procedure name: "児童扶養手当の受給者住所変更", html: "<p>児童扶養手当の受給者住所変更が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(印鑑 児童扶養手当証書 本人確認書類 マイナンバー確認書類 年金手帳 口座番号確認書類 所得課税証明書 障害者手帳),
                     procedure_applicant: %w(本人),
                     remarks: 'ひとり親家庭等に給付される児童扶養手当を受給している方は、引越し先の市区町村役所で住所変更の手続きが必要です。',
                     order: 160, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "ひとり親家庭等の医療費助成の申請", html: "<p>ひとり親家庭等の医療費助成の申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(健康保険証 児童扶養手当証書 本人確認書類 マイナンバー確認書類 所得課税証明書 印鑑 障害者手帳),
                     procedure_applicant: %w(本人),
                     remarks: 'ひとり親家庭等に対する医療費助成の制度が各市区町村にて用意されています。',
                     order: 170, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "特別児童扶養手当の受給者の住所変更の届出", html: "<p>特別児童扶養手当の受給者の住所変更の届出が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(印鑑 特別児童扶養手当証書),
                     procedure_applicant: %w(本人), order: 180,
                     applicable_column_ids: [
                       guide_columns['養育中の20歳未満の子どもがいる'].id, guide_columns['障害者の方がいる'].id
                     ]
save_guide_procedure name: "障害児福祉手当の受給資格者の住所変更の届出", html: "<p>障害児福祉手当の受給資格者の住所変更の届出が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(口座番号確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 190,
                     applicable_column_ids: [
                       guide_columns['養育中の20歳未満の子どもがいる'].id, guide_columns['障害者の方がいる'].id
                     ]
save_guide_procedure name: "特別障害者手当の受給資格者の住所変更の届出", html: "<p>特別障害者手当の受給資格者の住所変更の届出が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(口座番号確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 200,
                     applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "精神障害者保健福祉手帳の住所変更", html: "<p>精神障害者保健福祉手帳の住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(精神障害者保健福祉手帳 マイナンバー確認書類 本人確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 210,
                     applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "療育手帳の住所変更", html: "<p>療育手帳の住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(療育手帳 マイナンバー確認書類 本人確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 220,
                     applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "身体障害者手帳の住所変更", html: "<p>身体障害者手帳の住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(身体障害者手帳 マイナンバー確認書類 本人確認書類 印鑑),
                     procedure_applicant: %w(本人), order: 230,
                     applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "重度心身障害者の医療費助成の申請", html: "<p>重度心身障害者の医療費助成の申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(健康保険証 障害者手帳 所得課税証明書 印鑑 口座番号確認書類),
                     procedure_applicant: %w(本人),
                     remarks: '重度の障害がある方に対する医療費助成の制度が市区町村にて用意されています。',
                     order: 240, applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "自立支援医療受給者証の住所変更", html: "<p>自立支援医療受給者証の住所変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(健康保険証 自立支援医療受給者 印鑑),
                     procedure_applicant: %w(本人), order: 250,
                     applicable_column_ids: [guide_columns['障害者の方がいる'].id]
save_guide_procedure name: "要介護認定・要支援認定の継続申請", html: "<p>要介護認定・要支援認定の継続申請が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(介護保険被保険者証 介護保険受給資格証明書),
                     procedure_applicant: %w(本人),
                     remarks: '要介護認定・要支援認定の申請は、引越し先の市区町村役所で改めて行う必要がありますが、
引越しの日から14日以内に所定の申請をすれば審査を省略することができます。',
                     order: 260, applicable_column_ids: [guide_columns['前住所で要介護認定を受けている方がいる'].id]
save_guide_procedure name: "介護保険負担限度額認定申請の手続き", html: "<p>介護保険負担限度額認定申請の手続きが必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(通帳 印鑑), procedure_applicant: %w(本人),
                     remarks: '介護保険の負担限度額認定の申請は、引越し先の市町村役所所で改めて行う必要があります。',
                     order: 270, applicable_column_ids: [guide_columns['介護保険の負担限度額認定証の所持'].id]
save_guide_procedure name: "特定疾病療養受療証の交付申請", html: "<p>特定疾病療養受療証の交付申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(健康保険証 特定疾病療養受療証 本人確認書類 マイナンバー確認書類 印鑑),
                     procedure_applicant: %w(本人),
                     remarks: '国民健康保険または後期高齢者医療制度に加入している方のうち、特定疾病療養受療証の交付を受けている方は、
引越し先の市区町村役所に改めて交付申請が必要となることがあります。',
                     order: 280, applicable_column_ids: []
save_guide_procedure name: "高額療養費制度における認定証の発行申請", html: "<p>高額療養費制度における認定証の発行申請が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(健康保険証 限度額適用認定証 本人確認書類 マイナンバー確認書類 印鑑),
                     procedure_applicant: %w(本人),
                     remarks: '国民健康保険または後期高齢者医療制度の加入している方のうち、限度額適用認定証、
または限度額適用・標準負担額減額認定証をお持ちの方は、引越し先の市区町村役所に改めて認定の申請を出す必要があります。',
                     order: 290, applicable_column_ids: []
save_guide_procedure name: "高齢受給者証の発行", html: "<p>高齢受給者証の発行が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(負担及び減額区分証明書), procedure_applicant: %w(本人),
                     remarks: '国民健康保険の加入者で70～74歳の方は、引越し先の市区町村役所で高齢受給者証を発行してもらう必要があります。',
                     order: 300, applicable_column_ids: []
save_guide_procedure name: "犬の登録事項変更", html: "<p>犬の登録事項変更が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(鑑札 狂犬病予防注射済票),
                     procedure_applicant: %w(本人),
                     remarks: 'ペットとして犬を飼っている方は、引越し先の市区町村役所に届出が必要です。',
                     order: 310, applicable_column_ids: []
save_guide_procedure name: "印鑑登録", html: "<p>印鑑登録が必要です。</p>",
                     procedure_location: '市区町村役所', belongings: %w(印鑑登録をする印鑑 本人確認書類),
                     procedure_applicant: %w(本人),
                     remarks: '印鑑登録は市区町村ごとの管理となっているため、引越し先の市区町村役所で改めて印鑑登録を行う必要があります。',
                     order: 320, applicable_column_ids: []
save_guide_procedure name: "原付バイクの登録 (廃車手続き済)", html: "<p>原付バイクの登録 (廃車手続き済)が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(印鑑 本人確認書類 原付バイクの廃車証明書), procedure_applicant: %w(本人),
                     remarks: '原付バイクは市区町村ごとの管理となっているため、引越し先の市区町村役所に申告し、
ナンバープレートを交付してもらう必要があります。',
                     order: 330, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "小型特殊自動車の登録 (廃車手続き済)", html: "<p>小型特殊自動車の登録 (廃車手続き済)が必要です。</p>",
                     procedure_location: '市区町村役所',
                     belongings: %w(印鑑 本人確認書類 小型特殊自動車の廃車証明書), procedure_applicant: %w(本人),
                     remarks: '小型特殊自動車は市区町村ごとの管理となっているため、引越し先の市区町村役所に申告し、
ナンバープレートを交付してもらう必要があります。',
                     order: 340, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "不動産の名義人住所変更登記", html: "<p>不動産の名義人住所変更登記が必要です。</p>",
                     procedure_location: '法務局', belongings: %w(不動産登記申請書 住民票の写し),
                     procedure_applicant: %w(本人),
                     remarks: '土地や建物など不動産をお持ちの方は、不動産の変更登記が必要となります
複数回の引越しをしたあとでまとめて登記をすることも可能ですが、必要となる添付書類が変わるなど手続きが複雑になるケースがあります。',
                     order: 350, applicable_column_ids: []
save_guide_procedure name: "小中学校の転校手続き", html: "<p>小中学校の転校手続きが必要です。</p>",
                     procedure_location: '転校先の小中学校', belongings: %w(在学証明書 教科用図書給付証明書 転入学通知書),
                     procedure_applicant: %w(本人),
                     remarks: '公立の小中学校に通われているお子さんについては、転校のための手続きが必要となります。
転校手続きの前に、引越し先の市区町村役所で転入学通知書を取得する必要があります。',
                     order: 360, applicable_column_ids: [guide_columns['養育中の20歳未満の子どもがいる'].id]
save_guide_procedure name: "年金の住所変更", html: "<p>年金の住所変更が必要です。</p>",
                     procedure_location: '年金事務所 年金相談センター', belongings: %w(印鑑),
                     procedure_applicant: %w(本人),
                     remarks: '年金を受給している方は、住所変更の手続きが必要です。
ただし、マイナンバーと基礎年金番号が紐づいている方は手続きが不要となります。',
                     order: 370, applicable_column_ids: [guide_columns['年金を受給している方がいる'].id]
save_guide_procedure name: "勤務先における各種住所変更", html: "<p>勤務先における各種住所変更が必要です。</p>",
                     procedure_location: '勤務先', procedure_applicant: %w(本人),
                     remarks: '勤務先で社会保険に加入している方は、勤務先での手続きが必要となります。
勤務先の担当者に連絡して必要な情報を伝えましょう。',
                     order: 380, applicable_column_ids: []
save_guide_procedure name: "運転免許証の記載事項変更", html: "<p>運転免許証の記載事項変更が必要です。</p>",
                     procedure_location: '警察署 運転免許センター', belongings: %w(運転免許証 新住所確認書類),
                     procedure_applicant: %w(本人),
                     remarks: '運転免許証をお持ちの方は、警察署や運転免許センターにて記載事項変更の手続きが必要です。',
                     order: 390, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "軽自動車の保管場所届出 (所有地に保管)", html: "<p>軽自動車の保管場所届出 (所有地に保管)が必要です。</p>",
                     procedure_location: '警察署',
                     belongings: %w(自動車保管場所届出書 保管場所標章交付申請書 保管場所の所在図･配置図 保管場所標章交付手数料
                                    保管場所使用権原疎明書面),
                     procedure_applicant: %w(本人),
                     remarks: '軽自動車をお持ちの方は、引越しに際して軽自動車の保管場所が変わった場合、警察署へ届出が必要です。',
                     order: 400, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "普通自動車の保管場所証明申請 (所有地に保管)", html: "<p>普通自動車の保管場所証明申請 (所有地に保管)が必要です。</p>",
                     procedure_location: '警察署',
                     belongings: %w(自動車保管場所証明申請書 保管場所標章交付申請書 保管場所の所在図･配置図
                                    自動車保管場所証明書交付申請手数料 保管場所標章交付手数料 保管場所使用権原疎明書面),
                     procedure_applicant: %w(本人),
                     remarks: '普通自動車をお持ちの方は、引越しに際して自動車の保管場所が変わった場合、
保管場所証明申請を警察署に対して行う必要があります。',
                     order: 410, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "幼稚園に関する手続き", html: "<p>幼稚園に関する手続きが必要です。</p>",
                     procedure_location: '希望幼稚園', procedure_applicant: %w(本人),
                     remarks: 'この手続きを行うにあたっては、はじめに窓口でご相談されることをお勧めします。',
                     order: 420,
                     applicable_column_ids: [
                       guide_columns['養育中の20歳未満の子どもがいる'].id, guide_columns['子どもは小学校入学前である']
                     ]
save_guide_procedure name: "軽二輪の住所変更", html: "<p>軽二輪の住所変更が必要です。</p>",
                     procedure_location: '運輸支局 自動車検査登録事務所',
                     belongings: %w(軽自動車届出済証 住民票の写し 印鑑 自動車損害賠償責任保険証書 軽二輪のナンバープレート),
                     procedure_applicant: %w(本人),
                     remarks: '排気量126～250ccのバイク（軽二輪）は運輸支局ごとの管理となっているため、
引越し先の住所を管轄する運輸支局で住所変更の手続きが必要となります。',
                     order: 430, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "小型二輪の住所変更", html: "<p>小型二輪の住所変更が必要です。</p>",
                     procedure_location: '運輸支局 自動車検査登録事務所',
                     belongings: %w(自動車検査証 住民票の写し 印鑑 自動車損害賠償責任保険証書 軽二輪のナンバープレート
                                    ナンバープレート交付手数料),
                     procedure_applicant: %w(本人),
                     remarks: '排気量250cc超のバイク（小型二輪）は運輸支局ごとの管理となっているため、
引越し先の住所を管轄する運輸支局で住所変更の手続きが必要となります。',
                     order: 440, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "普通自動車の住所変更", html: "<p>普通自動車の住所変更が必要です。</p>",
                     procedure_location: '運輸支局',
                     belongings: %w(自動車検査証 住民票の写し 印鑑 自動車損害賠償責任保険証書 検査登録印紙 住民票の写し
                                    普通自動車のナンバープレート),
                     procedure_applicant: %w(本人),
                     remarks: '排気量250cc超のバイク（小型二輪）は運輸支局ごとの管理となっているため、
引越し先の住所を管轄する運輸支局で住所変更の手続きが必要となります。',
                     order: 450, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "軽自動車の住所変更", html: "<p>軽自動車の住所変更が必要です。</p>",
                     procedure_location: '軽自動車検査協会',
                     belongings: %w(自動車検査証 印鑑 住民票の写し (マイナンバーの記載のないもの)、または印鑑証明書
                                    軽自動車のナンバープレート),
                     procedure_applicant: %w(本人),
                     remarks: '軽自動車を持っている方は、軽自動車検査協会での住所変更手続きが必要です。',
                     order: 460, applicable_column_ids: [guide_columns['運転免許証の所持'].id]
save_guide_procedure name: "電気・ガス・水道の使用開始手続き", html: "<p>電気・ガス・水道の使用開始手続きが必要です。</p>",
                     procedure_applicant: %w(本人),
                     remarks: '引越し先で電気やガス、水道を使う場合にはそれぞれ業者に対して使用開始の手続きを行う必要があります。
インターネットまたは電話により手続きができます。 手続きに必要な持ち物は各事業者へご確認ください。',
                     order: 470, applicable_column_ids: []
save_guide_procedure name: "郵便物・宅急便等の転送の手続き", html: "<p>郵便物・宅急便等の転送の手続きが必要です。</p>",
                     belongings: %w(印鑑), procedure_applicant: %w(本人),
                     remarks: '郵便物や宅配便等が引越し先に転送されるように設定することができます。
各サービス窓口またはインターネットで手続きができます。',
                     order: 480, applicable_column_ids: []
# save_guide_procedure name: "各種証明書TEST", html: "<p>各種証明書TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['マイナンバーカードの所持'].id, guide_columns['マイナンバー通知カードの所持'].id,
#                        guide_columns['住民基本台帳カードの所持'].id, guide_columns['運転免許証の所持'].id
#                      ]
# save_guide_procedure name: "世帯の状況TEST", html: "<p>世帯の状況TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['妊娠中の方がいる'].id, guide_columns['養育中の20歳未満の子どもがいる'].id,
#                        guide_columns['年金を受給している方がいる'].id, guide_columns['障害者の方がいる'].id,
#                        guide_columns['前住所で要介護認定を受けている方がいる'].id,
#                        guide_columns['介護保険の負担限度額認定証の所持'].id, guide_columns['子どもは小学校入学前である'].id,
#                        guide_columns['子どもは小学生である'].id, guide_columns['子どもは中学生である'].id
#                      ]
# save_guide_procedure name: "子どもTEST", html: "<p>子どもTEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['公立小中学校に転校'].id, guide_columns['保育施設への入所を希望'].id,
#                        guide_columns['幼稚園施設への入所を希望'].id, guide_columns['学童保育への入所を希望'].id
#                      ]
# save_guide_procedure name: "世帯TEST", html: "<p>世帯TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['ひとり親家庭等である'].id
#                      ]
# save_guide_procedure name: "社会保険TEST", html: "<p>社会保険TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['会社や事業所の社会保険に加入している方がいる'].id,
#                        guide_columns['国民年金に新たに加入、または継続する方がいる'].id
#                      ]
# save_guide_procedure name: "社会保険などの加入状況TEST", html: "<p>社会保険などの加入状況TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['国民健康保険に加入、もしくは引続き加入する方がいる'].id,
#                        guide_columns['後期高齢者医療保険に加入している方がいる'].id,
#                        guide_columns['国民健康保険に加入されている方で、70歳～74歳の方がいる'].id,
#                        guide_columns['後期高齢者医療保険に加入している方は県外からの転入である'].id
#                      ]
# save_guide_procedure name: "福祉・介護TEST", html: "<p>福祉・介護TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['特定疾病療養受療証を持っている方がいる'].id,
#                        guide_columns['限度額適用認定証(または限度額適用・標準負担額減額認定証)を持っている方がいる'].id,
#                        guide_columns['父または母が障害者である'].id, guide_columns['精神障害者保健福祉手帳の所持'].id,
#                        guide_columns['療育手帳の所持'].id, guide_columns['身体障害者手帳の所持'].id,
#                        guide_columns['特別障害者手当を受給している方がいる'].id,
#                        guide_columns['重度心身障害者医療費受給者証の所持'].id, guide_columns['自立支援医療受給者証の所持'].id
#                      ]
# save_guide_procedure name: "所有する乗り物TEST", html: "<p>所有する乗り物TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['原付バイクの所持'].id, guide_columns['小型特殊自動車の所持'].id,
#                        guide_columns['126～250ccのバイク（軽二輪）の所持'].id,
#                        guide_columns['250cc超のバイク（小型二輪）の所持'].id, guide_columns['軽自動車の所持'].id,
#                        guide_columns['普通自動車の所持'].id,
#                        guide_columns['引越し前の市区町村役所で原付バイクの廃車の手続きを行っている'].id,
#                        guide_columns['引越し前の市区町村役所で小型特殊自動車の廃車の手続きを行っている'].id,
#                        guide_columns['転入先の地域は軽自動車の保管場所届出が必要な地域である'].id,
#                        guide_columns['自動車の保管場所は自分の所有地である'].id
#                      ]
# save_guide_procedure name: "不動産TEST", html: "<p>不動産TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['土地・家屋の所有'].id
#                      ]
# save_guide_procedure name: "その他TEST", html: "<p>その他TEST</p>", order: 0,
#                      applicable_column_ids: [
#                        guide_columns['印鑑登録'].id, guide_columns['犬を飼っている'].id
#                      ]

array = Guide::Procedure.where(site_id: @site._id).map { |m| [m.name, m] }
guide_procedures = Hash[*array.flatten]

save_node route: "cms/node", filename: "procedure", name: "目的別ガイド", layout_id: @layouts["one"].id

save_node route: "guide/node", filename: "procedure/move_in", name: "転入ガイド", layout_id: @layouts["one"].id,
          guide_index_html: '<p>転入に必要な手続きを確認します。</p>', guide_html: '<p>次の項目に該当しますか。</p>',
          procedure_ids: [
            guide_procedures['転入届 (転出証明書による手続き)'].id,
            guide_procedures['転入届 (転入届の特例による手続き)'].id,
            guide_procedures['転入届 (国外からの転入)'].id,
            guide_procedures['マイナンバーカードの住所変更'].id,
            guide_procedures['住民基本台帳カードの住所変更'].id,
            guide_procedures['マイナンバーカード交付申請'].id,
            guide_procedures['国民健康保険の加入届'].id,
            guide_procedures['後期高齢者医療保険の加入届 (県外からの転入)'].id,
            guide_procedures['国民年金の被保険者住所変更届'].id,
            guide_procedures['妊婦健康診査受診票の交付申請'].id,
            guide_procedures['児童手当の受給申請'].id,
            guide_procedures['子ども医療費助成の申請'].id,
            guide_procedures['転入学通知書の取得申請'].id,
            guide_procedures['保育所に関する手続き'].id,
            guide_procedures['学童保育の手続き'].id,
            guide_procedures['児童扶養手当の受給者住所変更'].id,
            guide_procedures['ひとり親家庭等の医療費助成の申請'].id,
            guide_procedures['特別児童扶養手当の受給者の住所変更の届出'].id,
            guide_procedures['障害児福祉手当の受給資格者の住所変更の届出'].id,
            guide_procedures['特別障害者手当の受給資格者の住所変更の届出'].id,
            guide_procedures['精神障害者保健福祉手帳の住所変更'].id,
            guide_procedures['療育手帳の住所変更'].id,
            guide_procedures['身体障害者手帳の住所変更'].id,
            guide_procedures['重度心身障害者の医療費助成の申請'].id,
            guide_procedures['自立支援医療受給者証の住所変更'].id,
            guide_procedures['要介護認定・要支援認定の継続申請'].id,
            guide_procedures['介護保険負担限度額認定申請の手続き'].id,
            guide_procedures['特定疾病療養受療証の交付申請'].id,
            guide_procedures['高額療養費制度における認定証の発行申請'].id,
            guide_procedures['高齢受給者証の発行'].id,
            guide_procedures['犬の登録事項変更'].id,
            guide_procedures['印鑑登録'].id,
            guide_procedures['原付バイクの登録 (廃車手続き済)'].id,
            guide_procedures['小型特殊自動車の登録 (廃車手続き済)'].id,
            guide_procedures['不動産の名義人住所変更登記'].id,
            guide_procedures['小中学校の転校手続き'].id,
            guide_procedures['年金の住所変更'].id,
            guide_procedures['勤務先における各種住所変更'].id,
            guide_procedures['運転免許証の記載事項変更'].id,
            guide_procedures['軽自動車の保管場所届出 (所有地に保管)'].id,
            guide_procedures['普通自動車の保管場所証明申請 (所有地に保管)'].id,
            guide_procedures['幼稚園に関する手続き'].id,
            guide_procedures['軽二輪の住所変更'].id,
            guide_procedures['小型二輪の住所変更'].id,
            guide_procedures['普通自動車の住所変更'].id,
            guide_procedures['軽自動車の住所変更'].id,
            guide_procedures['電気・ガス・水道の使用開始手続き'].id,
            guide_procedures['郵便物・宅急便等の転送の手続き'].id
            # guide_procedures['各種証明書TEST'].id, guide_procedures['世帯の状況TEST'].id, guide_procedures['子どもTEST'].id,
            # guide_procedures['世帯TEST'].id, guide_procedures['社会保険TEST'].id,
            # guide_procedures['社会保険などの加入状況TEST'].id, guide_procedures['福祉・介護TEST'].id,
            # guide_procedures['所有する乗り物TEST'].id, guide_procedures['不動産TEST'].id, guide_procedures['その他TEST'].id
          ]
