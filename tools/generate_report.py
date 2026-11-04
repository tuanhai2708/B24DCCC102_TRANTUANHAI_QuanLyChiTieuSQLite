"""Tạo báo cáo Word từ mã nguồn và bằng chứng thực nghiệm trong dự án.
Cài python-docx, pillow. Chạy tại thư mục gốc: python tools/generate_report.py
"""
from pathlib import Path
import json
import re
import sqlite3
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
META = json.loads((ROOT/'docs/report_metadata.json').read_text())
OUT = ROOT/'B24DCCC102_TRANTUANHAI_BaoCao.docx'
ASSETS = ROOT/'docs/report_assets'
SHOTS = ROOT/'docs/screenshots'
BLUE = '245BCC'
INK = '182D49'

# Vẽ bảng từ dữ liệu đã trích xuất thật, không giả làm Database Inspector.
def database_figure():
    data = json.loads((ASSETS/'database_evidence.json').read_text())
    img = Image.new('RGB', (1560, 1040), '#FFFFFF')
    d = ImageDraw.Draw(img)
    reg = str(ROOT/'assets/fonts/BeVietnamPro-Regular.ttf')
    sem = str(ROOT/'assets/fonts/BeVietnamPro-SemiBold.ttf')
    def font(n, bold=False): return ImageFont.truetype(sem if bold else reg, n)
    d.rectangle((0,0,1560,125),fill='#182D49')
    d.text((42,28),'Kiểm tra dữ liệu SQLite trên emulator Android',font=font(34,True),fill='white')
    d.text((42,82),'Nguồn: expense_manager.db trích qua ADB; không phải Database Inspector',font=font(21),fill='white')
    def grid(y,title,sql,headers,rows,widths):
        d.text((42,y),title,font=font(29,True),fill='#182D49')
        d.text((42,y+48),sql,font=font(23),fill='#5C6F88')
        y += 95
        for ri,row in enumerate([headers]+rows):
            x=42
            for cell,w in zip(row,widths):
                d.rectangle((x,y,x+w,y+64),fill='#245BCC' if ri==0 else ('#F3F7FC' if ri%2 else '#FFFFFF'),outline='#DFE7F2',width=2)
                d.text((x+12,y+17),str(cell) if cell is not None else 'NULL',font=font(23,ri==0),fill='white' if ri==0 else '#182D49')
                x+=w
            y+=64
        return y
    grid(155,'Bảng users','SELECT id, username, password FROM users;',
         ['id','username','password'],data['users'],[120,470,470])
    grid(425,'Bảng expenses','SELECT id, name, amount, category, date, note FROM expenses;',
         ['id','name','amount','category','date','note'],data['expenses'],[75,330,185,250,270,335])
    total=sum(r[2] for r in data['expenses'])
    d.text((42,865),f"Kết quả: {len(data['users'])} tài khoản, {len(data['expenses'])} khoản chi; tổng {total:,} VNĐ".replace(',','.'),font=font(28,True),fill='#182D49')
    d.text((42,925),'Dữ liệu mẫu: admin / 123456. Ngày trong bảng được lưu theo yyyy-MM-dd.',font=font(23),fill='#5C6F88')
    img.save(ASSETS/'database_query_results.png')


def setfont(style, name='Times New Roman', size=12):
    style.font.name = name
    style.font.size = Pt(size)
    style.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'), name)


def shade(cell, fill):
    sh = OxmlElement('w:shd'); sh.set(qn('w:fill'),fill)
    cell._tc.get_or_add_tcPr().append(sh)


def no_split(row):
    p = OxmlElement('w:cantSplit'); row._tr.get_or_add_trPr().append(p)


database_figure()
doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21), Cm(29.7)
sec.top_margin, sec.bottom_margin = Cm(1.8), Cm(1.8)
sec.left_margin, sec.right_margin = Cm(2.25), Cm(2.0)
sec.header_distance, sec.footer_distance = Cm(.7), Cm(.8)
sec.different_first_page_header_footer = True
for st in ['Normal','Body Text']:
    setfont(doc.styles[st],size=12)
    pf=doc.styles[st].paragraph_format
    pf.line_spacing=1.12; pf.space_after=Pt(6)
for st,size in [('Title',24),('Heading 1',17),('Heading 2',13),('Heading 3',12)]:
    setfont(doc.styles[st],size=size)
    doc.styles[st].font.color.rgb=RGBColor.from_string(INK)
    doc.styles[st].font.bold=True
    doc.styles[st].paragraph_format.space_after=Pt(8)
setfont(doc.styles['Caption'],size=10)
doc.styles['Caption'].font.italic=True
doc.styles['Caption'].paragraph_format.line_spacing=1.0
setfont(doc.styles['No Spacing'],size=11)
code_style=doc.styles.add_style('SQL Code',1)
setfont(code_style,name='Consolas',size=9.5)
code_style.paragraph_format.space_after=Pt(8)
code_style.paragraph_format.line_spacing=1.0
code_style.paragraph_format.keep_together=True
code_style.paragraph_format.left_indent=Cm(.25)
code_style.paragraph_format.right_indent=Cm(.15)
header=sec.header.paragraphs[0]
header.text='Trần Tuấn Hải  |  B24DCCC102  |  Quản lý chi tiêu SQLite'
header.runs[0].font.size=Pt(9); header.runs[0].font.color.rgb=RGBColor.from_string('5C6F88')
footer=sec.footer.paragraphs[0]
footer.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=footer.add_run('Trang '); r.font.size=Pt(10)
fld=OxmlElement('w:fldSimple'); fld.set(qn('w:instr'),'PAGE'); footer._p.append(fld)
props=doc.core_properties
props.title='Báo cáo bài thực hành 3 – Quản lý chi tiêu cá nhân với SQLite'
props.author='Trần Tuấn Hải'
props.subject='Flutter/Dart, SQLite – INT1449-20261-02'
props.keywords='B24DCCC102, Flutter, SQLite, báo cáo thực hành'

fig_number=0

def p(text, bold=False):
    q=doc.add_paragraph()
    q.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
    q.add_run(text).bold=bold
    return q

def h(text, level=2): return doc.add_heading(text,level)
def page(title):
    doc.add_page_break()
    return h(title,1)

def code(text):
    q=doc.add_paragraph(style='SQL Code')
    q.add_run(text.strip())
    sh=OxmlElement('w:shd'); sh.set(qn('w:fill'),'F1F4F8'); q._p.get_or_add_pPr().append(sh)
    return q

def table(headers, rows, widths=None):
    t=doc.add_table(rows=1,cols=len(headers)); t.style='Table Grid'; t.alignment=WD_TABLE_ALIGNMENT.CENTER
    for cell,text in zip(t.rows[0].cells,headers):
        cell.text=text; shade(cell,BLUE)
        for r in cell.paragraphs[0].runs: r.bold=True; r.font.color.rgb=RGBColor(255,255,255)
    repeat=OxmlElement('w:tblHeader'); t.rows[0]._tr.get_or_add_trPr().append(repeat)
    for row in rows:
        cells=t.add_row().cells
        for c,text in zip(cells,row): c.text=str(text)
    for row in t.rows:
        no_split(row)
        for i,c in enumerate(row.cells):
            c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            if widths: c.width=Cm(widths[i])
            for q in c.paragraphs:
                q.paragraph_format.space_after=Pt(4); q.paragraph_format.space_before=Pt(4)
                q.paragraph_format.line_spacing=1.05
                for r in q.runs:
                    r.font.size=Pt(10.5)
    doc.add_paragraph().paragraph_format.space_after=Pt(0)
    return t

def caption(q,text):
    global fig_number
    fig_number+=1
    q.style=doc.styles['Caption']; q.alignment=WD_ALIGN_PARAGRAPH.CENTER
    q.add_run(f'Hình {fig_number}. {text}')

def shots(items, width=6.55):
    t=doc.add_table(rows=1,cols=len(items)); t.alignment=WD_TABLE_ALIGNMENT.CENTER
    borders=OxmlElement('w:tblBorders')
    for edge in ['top','left','bottom','right','insideH','insideV']:
        e=OxmlElement('w:'+edge); e.set(qn('w:val'),'nil'); borders.append(e)
    t._tbl.tblPr.append(borders)
    no_split(t.rows[0])
    for cell,(file,desc) in zip(t.rows[0].cells,items):
        q=cell.paragraphs[0]; q.alignment=WD_ALIGN_PARAGRAPH.CENTER
        q.paragraph_format.space_after=Pt(5)
        q.add_run().add_picture(str(file),width=Cm(width))
        caption(cell.add_paragraph(),desc)
    doc.add_paragraph().paragraph_format.space_after=Pt(0)

def sql_block(title,method,sql,explanation):
    h(title)
    p('Phương thức: '+method+'.',True)
    code(sql)
    p(explanation)

# Trang bìa
for _ in range(2): doc.add_paragraph()
q=doc.add_paragraph(); q.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=q.add_run('BÁO CÁO BÀI THỰC HÀNH SỐ 3'); r.bold=True; r.font.size=Pt(18)
q=doc.add_paragraph(); q.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=q.add_run('ỨNG DỤNG QUẢN LÝ\nCHI TIÊU CÁ NHÂN'); r.bold=True; r.font.size=Pt(24); r.font.color.rgb=RGBColor.from_string(INK)
q=doc.add_paragraph(); q.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=q.add_run('Kết nối cơ sở dữ liệu SQLite\nTriển khai bằng Flutter / Dart'); r.font.size=Pt(16)
for _ in range(2): doc.add_paragraph()
for label,value in [('Họ và tên',META['name']),('Mã số sinh viên',META['student_id']),('Lớp',META['class'])]:
    q=doc.add_paragraph(); q.paragraph_format.left_indent=Cm(1.4)
    q.add_run(label+': ').bold=True; q.add_run(value)
q=doc.add_paragraph(); q.paragraph_format.left_indent=Cm(1.4); q.add_run('Repository GitHub:').bold=True
q=doc.add_paragraph(META['repository_url']); q.paragraph_format.left_indent=Cm(1.4)
for r in q.runs: r.font.size=Pt(11); r.font.color.rgb=RGBColor.from_string(BLUE)
q=doc.add_paragraph(); q.paragraph_format.left_indent=Cm(1.4); q.add_run('Tên repository: ').bold=True
q.add_run(META['repository_name']).font.size=Pt(10.5)
doc.add_paragraph()
q=doc.add_paragraph('Ngày lập báo cáo: 04/11/2026'); q.alignment=WD_ALIGN_PARAGRAPH.CENTER
q=doc.add_paragraph('Báo cáo mô tả mã nguồn và ảnh chạy thực tế của bản Flutter.\nẢnh kiểm tra dữ liệu SQLite được ghi đúng nguồn; cần bổ sung ảnh Database Inspector trước khi nộp nếu giảng viên yêu cầu đúng công cụ này.')
q.alignment=WD_ALIGN_PARAGRAPH.CENTER
for r in q.runs: r.font.size=Pt(10); r.italic=True

page('1. Tổng quan và tổ chức chương trình')
p('Ứng dụng Sổ chi tiêu giúp ghi nhận các khoản chi cá nhân, tìm lại theo tên, lọc theo danh mục và theo dõi tổng tiền. Dữ liệu được chuyển từ lưu tạm trong bộ nhớ sang tệp SQLite để vẫn còn sau khi tắt hẳn và mở lại ứng dụng.')
p('Bản triển khai sử dụng Flutter/Dart theo yêu cầu thay cho Java/XML trong đề. Các chức năng và cấu trúc dữ liệu được giữ tương ứng; phần mô tả dưới đây sử dụng đúng tên widget, Navigator và sqflite trong mã nguồn.')
table(['Thành phần trong đề','Triển khai trong dự án'],[
 ('Activity / layout XML','StatefulWidget, Scaffold và các widget Material'),
 ('Intent truyền id','Navigator + MaterialPageRoute; tham số expenseId'),
 ('SQLiteOpenHelper','DatabaseHelper với sqflite, callback _onCreate'),
 ('ContentValues / Cursor','Map<String, Object?> và kết quả List<Map>; sqflite quản lý Cursor native'),
 ('RecyclerView / Adapter','ListView và các widget dựng từ dữ liệu truy vấn'),
 ('TextWatcher / Spinner','TextField.onChanged / DropdownButtonFormField'),
 ('DatePicker / ProgressBar','showDatePicker / LinearProgressIndicator'),
])
h('1.1. Luồng năm màn hình')
code('Đăng nhập → Danh sách chi tiêu\nDanh sách → Thêm khoản chi → Danh sách\nDanh sách → Chi tiết → Sửa khoản chi → Chi tiết\nChi tiết → Xác nhận xóa → Danh sách\nDanh sách → Thống kê → Danh sách')
p('Đăng nhập thành công dùng pushReplacement nên nút quay lại không trở về màn đăng nhập cũ. Mỗi màn chi tiết hoặc sửa chỉ nhận id, sau đó tự truy vấn lại database. Khi quay lại danh sách, _open() gọi _refresh() để tải lại danh sách và tổng.')
h('1.2. Tệp mã nguồn chính')
p('lib/models/expense.dart chứa mô hình và validation; lib/data/database_helper.dart tập trung SQLite; lib/screens chứa năm màn hình; lib/theme.dart định dạng tiền/ngày và giao diện; lib/widgets/common.dart chứa thành phần dùng chung.')

page('2. Thiết kế cơ sở dữ liệu SQLite')
p('Database có tên expense_manager.db, phiên bản 1, được mở qua _open() bằng DatabaseFactory.openDatabase(). Callback _onCreate() tạo hai bảng và chèn dữ liệu mẫu. Chỉ chạy khởi tạo khi tệp database chưa tồn tại; mở lại không chèn lại mẫu.')
h('2.1. Bảng users')
table(['Cột','Kiểu và ràng buộc','Ý nghĩa'],[
 ('id','INTEGER PRIMARY KEY AUTOINCREMENT','Mã tài khoản'),('username','TEXT NOT NULL UNIQUE','Tên đăng nhập'),('password','TEXT NOT NULL','Mật khẩu thực hành, lưu nguyên văn'),])
h('2.2. Bảng expenses')
table(['Cột','Kiểu và ràng buộc','Ý nghĩa'],[
 ('id','INTEGER PRIMARY KEY AUTOINCREMENT','Mã khoản chi'),('name','TEXT NOT NULL','Tên khoản chi'),('amount','INTEGER NOT NULL; CHECK(amount > 0)','Số tiền nguyên VNĐ'),('category','TEXT NOT NULL','Ăn uống, Đi lại, Học tập, Giải trí, Khác'),('date','TEXT NOT NULL','Ngày theo yyyy-MM-dd'),('note','TEXT, có thể NULL','Ghi chú không bắt buộc'),])
p('Expense có các thuộc tính id, name, amount, category, date, note. fromMap() chuyển dòng SQL thành đối tượng; toMap() chuẩn hóa tên/ghi chú và chuyển ngày sang yyyy-MM-dd. Khi note trong SQL là NULL, ứng dụng dùng chuỗi rỗng để hiển thị an toàn.')
h('2.3. Các phương thức của DatabaseHelper')
p('checkLogin() kiểm tra tài khoản; insertExpense(), updateExpense(), deleteExpense() thực hiện CRUD; getExpenseById() đọc theo id; getExpenses() tìm/lọc/sắp xếp; getTotal() tính tổng; getTotalByCategory() thống kê nhóm. getSummary() bổ sung transaction để danh sách và tổng phản ánh cùng thời điểm; close() đóng kết nối khi kiểm thử.')
p('Phiên bản hiện tại chưa có migration vì mới ở version 1. Nếu nâng schema về sau phải tăng version và bổ sung onUpgrade, tránh xóa dữ liệu cũ. Câu SQL đầy đủ nằm ở chương 4 của báo cáo.')

page('2.4. Dữ liệu khởi tạo và kiểm tra thực tế')
q=doc.add_paragraph(); q.alignment=WD_ALIGN_PARAGRAPH.CENTER
q.add_run().add_picture(str(ASSETS/'database_query_results.png'),width=Cm(16.2))
caption(doc.add_paragraph(),'Kết quả truy vấn hai bảng từ tệp SQLite thật của ứng dụng trên Android; hình trình bày lại dữ liệu trích qua ADB.')
p('Kết quả ghi nhận bảng users có tài khoản admin / 123456. Bảng expenses có ba dòng: Ăn sáng 30.000 đồng ngày 13/10/2026, Đổ xăng 50.000 đồng ngày 12/10/2026, Mua sách 120.000 đồng ngày 11/10/2026. Tổng dữ liệu mẫu là 200.000 đồng.')
p('Tệp được đọc từ vùng dữ liệu riêng của package vn.edu.th411.quan_ly_chi_tieu bằng lệnh ADB dưới đây. Các dòng được truy vấn bằng sqlite3 và được lưu lại trong docs/report_assets/database_evidence.json; hình không sử dụng số liệu dựng giả.')
code('adb exec-out run-as vn.edu.th411.quan_ly_chi_tieu \\\n  cat databases/expense_manager.db\n\nSELECT id, username, password FROM users;\nSELECT id, name, amount, category, date, note FROM expenses;')
p('Đối chiếu yêu cầu ảnh: hình trên là kết quả kiểm tra bằng ADB/sqlite3, không phải ảnh Database Inspector. Máy thực hiện chưa cài Android Studio. Trước khi nộp theo đúng yêu cầu công cụ của đề, cần bổ sung ảnh Database Inspector hiển thị users và expenses; không đổi nhãn hình này thành ảnh Inspector.',True)

page('3. Chức năng và minh chứng giao diện')
h('3.1. Đăng nhập')
shots([(SHOTS/'02_dang_nhap_sai.png','Đăng nhập sai: thông báo lỗi, giữ nguyên màn hình.'),(SHOTS/'03_danh_sach.png','Đăng nhập đúng: chuyển sang danh sách, tổng ban đầu 200.000 đ.')])
p('LoginScreen sử dụng Form và hai TextFormField. Validator chặn tên đăng nhập hoặc mật khẩu trống; mật khẩu được ẩn bằng obscureText và có nút hiện/ẩn. Khi nhấn Đăng nhập, _login() gọi checkLogin(username, password) để SELECT từ users bằng hai tham số ?. Thông tin tài khoản không được so sánh cố định trong widget.')
p('Nếu không có dòng khớp, màn hình hiển thị “Tên đăng nhập hoặc mật khẩu không đúng.”. Khi hợp lệ, Navigator.pushReplacement() mở HomeScreen. Cờ _busy khóa thao tác đăng nhập lặp trong lúc chờ và lỗi mở database được thông báo để thử lại.')

page('3.2. Danh sách và tìm kiếm khoản chi')
shots([(SHOTS/'03_danh_sach.png','Danh sách đọc từ SQLite, mỗi dòng có tên, danh mục, ngày và tiền.'),(SHOTS/'04_tim_kiem.png','Tìm “Ăn sáng”: còn một khoản phù hợp, tổng 30.000 đ.')])
p('HomeScreen dùng TextEditingController cho ô tìm kiếm. TextField.onChanged gọi _refresh() mỗi khi nội dung đổi. _query() truyền từ khóa và danh mục hiện tại cho getSummary(); lớp này dùng cùng điều kiện lọc cho SELECT danh sách và SUM trong một transaction.')
p('ListView dựng các dòng bằng widget từ Expense; đây là phần tương đương Adapter trong bản Android Java. Tên chứa từ khóa được tìm bằng LIKE; dữ liệu sắp xếp ORDER BY date DESC, id DESC. TotalPanel hiển thị tổng và số khoản đúng bộ lọc. _open() chờ màn hình con đóng rồi tải lại, đồng thời danh sách làm mới khi ứng dụng trở lại trạng thái resumed.')

page('3.3. Lọc danh mục và danh sách rỗng')
shots([(SHOTS/'05_loc_danh_muc.png','Lọc Học tập: hiển thị Mua sách, tổng 120.000 đ.'),(ASSETS/'15_danh_sach_rong.png','Tìm không có kết quả: hiển thị trạng thái rỗng và tổng 0 đ.')])
p('DropdownButtonFormField có lựa chọn Tất cả danh mục và năm danh mục theo đề. Khi chọn một nhóm, _category được cập nhật và truy vấn thêm AND category = ?. Nếu chọn Tất cả danh mục thì bỏ điều kiện nhóm. Từ khóa và danh mục có thể được dùng cùng lúc.')
p('Khi không có dòng trả về, ứng dụng hiển thị “Chưa có khoản chi nào” cùng hướng dẫn đổi từ khóa hoặc danh mục; tổng bằng 0 và số khoản bằng 0. _filter() escape ký tự %, _ và dấu gạch chéo để tìm theo nghĩa đen. Dữ liệu người dùng luôn được truyền bằng tham số, tránh nối trực tiếp vào SQL.')

page('3.4. Thêm khoản chi và kiểm tra dữ liệu')
shots([(SHOTS/'06_them.png','Form thêm gồm tên, tiền, danh mục, ngày, ghi chú và nút lưu.'),(SHOTS/'07_loi_form.png','Không cho lưu khi tên và số tiền chưa hợp lệ.')])
p('EditScreen không có expenseId là chế độ thêm: tiêu đề “Thêm khoản chi”, nút “Lưu khoản chi”. Form yêu cầu tên không trống và tiền là số nguyên lớn hơn 0; bộ lọc chỉ cho nhập chữ số, tối đa 15 chữ số. Ghi chú nhiều dòng là tùy chọn.')
p('showDatePicker() giới hạn lastDate là hôm nay, không cho chọn ngày tương lai. Khi _save() chạy, dữ liệu còn được kiểm tra lại bởi Expense.validate(), rồi insertExpense() lưu Map vào bảng expenses. Lưu thành công đóng form bằng Navigator.pop(true); danh sách và tổng được đọc lại từ database.')

page('3.5. Sửa khoản chi theo id')
shots([(SHOTS/'09_sua.png','Form sửa đã nạp khoản “Bữa trưa ở trường”, số tiền 45.000 đ.'),(SHOTS/'08_chi_tiet.png','Thông tin gốc của khoản chi trước khi chỉnh sửa.')])
p('Khi nhấn Sửa khoản chi từ chi tiết, Navigator mở EditScreen với expenseId. _editing nhận biết chế độ sửa; _load() gọi getExpenseById(id) và gán dữ liệu cũ vào các controller, danh mục và ngày. Tiêu đề đổi thành “Sửa khoản chi”, nút đổi thành “Cập nhật khoản chi”.')
p('Trong luồng kiểm thử, khoản Bữa trưa ở trường được đổi từ 45.000 thành 55.000 đồng. _save() gọi updateExpense() với WHERE id = ?; nếu số dòng thay đổi bằng 0 thì báo chưa lưu được. Sau khi form đóng, DetailScreen._edit() gọi _reload() để đọc lại dữ liệu. Ảnh xác nhận xóa ở mục sau ghi nhận số tiền mới 55.000 đồng.')

page('3.6. Chi tiết và xác nhận xóa')
shots([(SHOTS/'08_chi_tiet.png','Chi tiết đọc theo id: tên, tiền, danh mục, ngày và ghi chú.'),(SHOTS/'10_xac_nhan_xoa.png','Xác nhận xóa sau khi đã sửa tiền lên 55.000 đ.')])
p('DetailScreen nhận expenseId và gọi getExpenseById() khi khởi tạo. Màn hình hiển thị đầy đủ dữ liệu, tiền có phân cách hàng nghìn, ngày dd/MM/yyyy; ghi chú trống hiển thị “Không có ghi chú”. Nếu id không còn tồn tại, hiển thị thông báo và cho quay lại.')
p('Nhấn Xóa khoản chi mở AlertDialog bằng showDialog<bool>(). Chọn Hủy chỉ đóng hộp thoại và giữ dữ liệu; chọn Xóa mới gọi deleteExpense(id) với WHERE id = ?. Cờ _deleting chặn thao tác lặp khi đang xóa. Thành công thì pop về danh sách và đọc lại tổng/dữ liệu.')

page('3.7. Danh sách sau khi xóa')
shots([(SHOTS/'11_sau_khi_xoa.png','Khoản chi kiểm thử đã bị xóa; còn ba khoản mẫu và tổng 200.000 đ.')],width=6.6)
p('Trong phép thử, ứng dụng tạo khoản mới 45.000 đồng, sửa lên 55.000 đồng, hủy xóa một lần rồi xác nhận xóa. Sau xóa, SELECT danh sách không còn khoản kiểm thử; tổng trở về 200.000 đồng của ba khoản mẫu. Như vậy giao diện phản ánh dữ liệu sau DELETE, thay vì chỉ xóa tạm một dòng trong bộ nhớ.')
p('Mỗi lần HomeScreen._open() nhận kết quả quay lại từ màn con, _refresh() tạo Future truy vấn mới. LoadView/FutureBuilder biểu diễn trạng thái chờ và lỗi đọc dữ liệu, có nút Thử lại. Người dùng cũng có thể kéo danh sách để tải lại qua RefreshIndicator.')

page('3.8. Thống kê theo danh mục')
shots([(SHOTS/'12_thong_ke.png','Thống kê đủ năm nhóm: 15%, 25%, 60%, 0% và 0%.')],width=6.6)
p('StatisticsScreen gọi getTotalByCategory() với SELECT category, SUM(amount) AS total FROM expenses GROUP BY category. Map kết quả được khởi tạo đủ năm danh mục bằng 0 rồi ghi đè số liệu truy vấn, nên Giải trí và Khác vẫn xuất hiện dù chưa có khoản chi.')
p('Tổng chung là tổng các giá trị nhóm; tỷ lệ nhóm bằng số tiền nhóm chia tổng chung. Với dữ liệu mẫu: Ăn uống 30.000/200.000 = 15%; Đi lại 50.000/200.000 = 25%; Học tập 120.000/200.000 = 60%. LinearProgressIndicator nhận tỷ lệ trong khoảng 0–1; khi tổng bằng 0 thì tỷ lệ được đặt 0 để tránh chia cho 0.')

page('3.9. Lưu trữ bền vững sau khi tắt hẳn')
shots([(ASSETS/'16_truoc_force_stop.png','Trước force-stop: thêm khoản “Kiem tra luu tru” 10.000 đ.'),(ASSETS/'17_sau_force_stop.png','Sau force-stop, mở lại và đăng nhập: khoản chi vẫn còn.')])
p('Phép thử chạy trên bản ứng dụng thường với expense_manager.db. Sau khi thêm khoản Kiem tra luu tru, tổng tăng từ 200.000 lên 210.000 đồng. Lệnh am force-stop dừng tiến trình package; kiểm tra pidof sau đó không còn tiến trình. Mở lại MainActivity, đăng nhập và chụp danh sách: khoản 10.000 đồng cùng tổng 210.000 đồng vẫn được giữ.')
p('SQLite ghi dữ liệu vào tệp trong vùng lưu trữ riêng của ứng dụng. Việc kết thúc tiến trình chỉ làm mất trạng thái RAM; tệp database vẫn còn và _onCreate() không chạy lại nếu tệp đã tồn tại. Khác với ArrayList, dữ liệu được INSERT/UPDATE/DELETE trong tệp nên thay đổi tồn tại qua các lần mở. Gỡ ứng dụng hoặc xóa dữ liệu ứng dụng sẽ xóa tệp này.')

page('4. Các câu lệnh SQL sử dụng trong ứng dụng')
p('Tất cả câu SQL dưới đây tương ứng với lib/data/database_helper.dart. Với API insert(), update(), delete() và query(), báo cáo trình bày câu SQL tương đương đầy đủ. Ký hiệu ? nhận giá trị qua danh sách tham số; không nối chuỗi nhập của người dùng vào câu SQL.')
sql_block('4.1. CREATE TABLE users','_onCreate(Database db, int version)', '''CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
);''','Tạo bảng tài khoản. id tự tăng; username bắt buộc và duy nhất; password bắt buộc. Theo phạm vi bài thực hành, mật khẩu lưu nguyên văn.')
sql_block('4.2. CREATE TABLE expenses','_onCreate(Database db, int version)', '''CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK(amount > 0),
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  note TEXT
);''','Tạo bảng chi tiêu có khóa chính id và ràng buộc tiền dương. Ngày lưu dạng yyyy-MM-dd để ORDER BY theo thời gian đúng. Ghi chú có thể NULL; việc kiểm tra danh mục và ngày còn được thực hiện trong Expense.validate().')

page('4.3. INSERT dữ liệu khởi tạo và khoản mới')
p('Phương thức: _onCreate(Database db, int version). Các câu bên dưới ghi đầy đủ giá trị mẫu tương đương với rawInsert có tham số trong mã nguồn.',True)
code("""INSERT INTO users (username, password)
VALUES ('admin', '123456');

INSERT INTO expenses (name, amount, category, date)
VALUES ('Ăn sáng', 30000, 'Ăn uống', '2026-10-13');

INSERT INTO expenses (name, amount, category, date)
VALUES ('Đổ xăng', 50000, 'Đi lại', '2026-10-12');

INSERT INTO expenses (name, amount, category, date)
VALUES ('Mua sách', 120000, 'Học tập', '2026-10-11');""")
p('Tài khoản mẫu được thêm bằng rawInsert, ba khoản mẫu được thêm qua batch. Callback onCreate của sqflite nằm trong transaction; nếu tạo/khởi tạo lỗi thì không lưu một phần dữ liệu. Những câu này không chạy lại mỗi lần đăng nhập.')
sql_block('4.4. Thêm một khoản chi','insertExpense(Expense expense)', '''INSERT INTO expenses (name, amount, category, date, note)
VALUES (?, ?, ?, ?, ?);''','Tương đương db.insert("expenses", expense.toMap()). Năm tham số lần lượt là tên đã trim, số tiền nguyên, danh mục, ngày ISO và ghi chú. Phương thức trả id mới; khi có lỗi, exception được màn hình bắt và thông báo để thử lại. Phiên bản Flutter sử dụng exception thay vì trả -1 như gợi ý Java trong đề.')

page('4.5. SELECT tài khoản và khoản chi theo id')
sql_block('Kiểm tra đăng nhập','checkLogin(String username, String password)', '''SELECT id FROM users
WHERE username = ? AND password = ?
LIMIT 1;''','Tham số là username đã trim và password. Có ít nhất một dòng là hợp lệ. Trường trống được chặn trước khi truy vấn; LIMIT 1 đủ để kiểm tra tồn tại.')
sql_block('Lấy khoản chi theo mã','getExpenseById(int id)', '''SELECT * FROM expenses
WHERE id = ?
LIMIT 1;''','Tương đương db.query("expenses", where: "id = ?", whereArgs: [id], limit: 1). Kết quả được chuyển bằng Expense.fromMap(). Không có dòng thì trả null. Chi tiết và form sửa tự đọc lại theo id.')
h('4.6. Tìm kiếm kết hợp lọc danh mục')
p('Phương thức: getExpenses({String keyword, String? category}) và getSummary().',True)
code("""SELECT * FROM expenses
WHERE name LIKE ? ESCAPE '\\' AND category = ?
ORDER BY date DESC, id DESC;""")
p('Ví dụ tìm “Ăn” trong Ăn uống: tham số là ["%Ăn%", "Ăn uống"]. _filter() escape dấu %, _ và \\ trong chuỗi nhập; chuỗi từ khóa sau đó được bao bằng %. Chỉ phần cấu trúc SQL cố định được ghép; giá trị người dùng đi qua tham số.')
code("""SELECT * FROM expenses
WHERE name LIKE ? ESCAPE '\\'
ORDER BY date DESC, id DESC;""")
p('Câu thứ hai dùng khi chọn Tất cả danh mục. Ngày mới nhất trước; cùng ngày thì id lớn hơn trước. Từ khóa rỗng dùng %% để lấy mọi tên.')

page('4.7. SELECT SUM và GROUP BY')
sql_block('Tổng tiền theo từ khóa và danh mục','getTotal() và getSummary()', """SELECT COALESCE(SUM(amount), 0) AS total
FROM expenses
WHERE name LIKE ? ESCAPE '\\' AND category = ?;""",'Dùng cùng điều kiện và tham số với danh sách. SUM cộng amount; COALESCE chuyển kết quả NULL thành 0 khi không có dòng. getSummary() chạy SELECT danh sách và SUM trong cùng transaction để bảo đảm nhất quán.')
sql_block('Tổng tiền khi chọn tất cả danh mục','getTotal() và getSummary()', """SELECT COALESCE(SUM(amount), 0) AS total
FROM expenses
WHERE name LIKE ? ESCAPE '\\';""",'Khi không giới hạn danh mục, bỏ điều kiện category nhưng vẫn áp dụng từ khóa. Từ khóa rỗng tương ứng tổng mọi khoản chi.')
sql_block('Tổng theo từng nhóm','getTotalByCategory()', '''SELECT category, SUM(amount) AS total
FROM expenses
GROUP BY category;''','SQLite gộp các khoản cùng category. Phần Dart bổ sung danh mục chưa có dòng với số 0. StatisticsScreen lấy tổng chung từ các nhóm và tính phần trăm; năm danh mục đều được hiển thị kể cả 0 đ, 0%.')

page('4.8. UPDATE và DELETE theo id')
sql_block('Cập nhật khoản chi','updateExpense(Expense expense)', '''UPDATE expenses
SET name = ?, amount = ?, category = ?, date = ?, note = ?
WHERE id = ?;''','Tương đương db.update("expenses", expense.toMap(), where: "id = ?", whereArgs: [expense.id]). Các giá trị mới được chuẩn hóa và kiểm tra trước khi ghi; WHERE chỉ sửa bản ghi đúng id. Phương thức trả số dòng bị thay đổi, form kiểm tra kết quả bằng 0 để không báo thành công sai.')
sql_block('Xóa khoản chi','deleteExpense(int id)', '''DELETE FROM expenses
WHERE id = ?;''','Tương đương db.delete("expenses", where: "id = ?", whereArgs: [id]). Chỉ thực hiện sau khi hộp thoại xác nhận trả true. Sau DELETE, màn chi tiết đóng; danh sách và tổng được truy vấn lại.')
h('4.9. Quản lý kết nối và tham số')
p('Các truy vấn dùng tham số ? và whereArgs/args; không có thao tác ghép trực tiếp tên khoản chi, danh mục hay tài khoản vào SQL. sqflite quản lý Cursor và trả List<Map<String, Object?>> cho Dart, nên mã Flutter không có Cursor Java để đóng thủ công. Kết nối được dùng chung theo DatabaseHelper.instance trong ứng dụng; close() được dùng khi kiểm thử mở lại tệp.')
p('Ngày trong toMap() luôn lưu bằng databaseDate() theo yyyy-MM-dd; giao diện dùng displayDate() theo dd/MM/yyyy. amount là int, hiển thị bằng NumberFormat.decimalPattern("vi_VN") và hậu tố đ. Định dạng giao diện không làm thay đổi kiểu dữ liệu SQL.')

page('5. Kiểm thử và kết quả')
p('Môi trường thực hiện: Flutter 3.47.9, Dart 3.13.7; emulator Android arm64 API 37.1; bản Android compile/target SDK 36, min SDK 24. Ảnh giao diện trong báo cáo được chụp từ ứng dụng Flutter chạy trên Android, không phải bản phác thảo.')
table(['Kiểm thử','Kết quả ghi nhận'],[
 ('flutter analyze','Không có vấn đề phân tích mã.'),
 ('flutter test','11/11 kiểm thử đạt: 8 SQLite, 3 giao diện.'),
 ('SQLite qua FFI','Đúng seed, tài khoản, CRUD, tìm/lọc, sắp xếp, tổng và 5 nhóm; kiểm tra tham số SQL và dữ liệu không hợp lệ.'),
 ('Tệp SQLite thật','Đóng và mở lại vẫn giữ thay đổi thêm/sửa/xóa; không chèn lại seed.'),
 ('Giao diện','Chặn trống/sai, tìm kiếm/rỗng, thêm/sửa/xóa có hủy; màn 320 px, cỡ chữ 150% không tràn trong các màn được kiểm tra.'),
 ('Tích hợp Android','Đi qua năm màn hình trên SQLite native; đã lưu 14 ảnh từ integration_test.'),
 ('Force-stop thực tế','Dừng tiến trình, mở lại và đăng nhập: khoản 10.000 đ vẫn còn, tổng 210.000 đ.'),
 ('flutter build apk --debug','Build APK thành công; vị trí build/app/outputs/flutter-apk/app-debug.apk.'),
])
h('5.1. Tệp kiểm thử và khả năng tái lập')
p('test/database_helper_test.dart kiểm tra truy vấn và lưu tệp; test/widget_test.dart kiểm tra giao diện; integration_test/app_test.dart chạy SQLite native trên Android. test_driver/integration_test.dart lưu ảnh về docs/screenshots. Hai ảnh force-stop mới và dữ liệu kiểm chứng bổ sung được lưu tại docs/report_assets.')
code('flutter pub get\nflutter analyze\nflutter test\nflutter test integration_test/app_test.dart -d <device-id>\nflutter build apk --debug')
h('5.2. Giới hạn của bản thực hành')
p('Mật khẩu lưu nguyên văn đúng phạm vi đề, chưa phù hợp tài khoản sản phẩm thực tế. LIKE mặc định của SQLite không phải tìm bỏ dấu và có giới hạn so khớp hoa/thường Unicode. Phiên bản này lưu SQLite native, không chạy Chrome. Build iOS/macOS chưa được xác minh trên máy không có Xcode.')

page('6. Mã nguồn Git và đối chiếu yêu cầu nộp')
p('Repository: '+META['repository_url'])
p('Tên repository: '+META['repository_name'])
p('Repository chứa mã Flutter, cấu hình Android/iOS/macOS, pubspec.yaml, pubspec.lock, kiểm thử, tài liệu SQL, ảnh minh chứng và file báo cáo. Không nộp dự án dưới dạng ZIP. .gitignore loại build, .gradle, .idea, local.properties, tệp database, khóa ký và các tệp sinh tự động theo nền tảng.')
h('6.1. Cách chạy sau khi lấy mã')
code('git clone '+META['repository_url']+'.git\ncd '+META['repository_name']+'\nflutter pub get\nflutter run -d <device-id>')
p('Tài khoản thực hành khi database được tạo lần đầu: admin / 123456. Sau khi thêm, sửa hoặc xóa, cần giữ dữ liệu ứng dụng nếu muốn kiểm chứng lưu bền vững; không gỡ cài đặt hay xóa dữ liệu giữa hai lần chạy.')
h('6.2. Đối chiếu với các mục báo cáo')
table(['Nội dung yêu cầu','Vị trí / trạng thái'],[
 ('Họ tên, MSSV, lớp, link Git','Trang bìa và chương 6.'),
 ('Cấu trúc users và expenses','Chương 2; đã kiểm tra dữ liệu thật bằng ADB/sqlite3.'),
 ('Ảnh Database Inspector','Chưa có ảnh đúng công cụ; cần bổ sung trước khi nộp nếu áp dụng yêu cầu này nguyên văn.'),
 ('Đăng nhập đúng và sai','Mục 3.1: ảnh và mô tả SELECT, validation, điều hướng.'),
 ('Danh sách, tìm kiếm, lọc, rỗng','Mục 3.2–3.3: ảnh và mô tả truy vấn.'),
 ('Thêm, sửa, lỗi form','Mục 3.4–3.5: ảnh và mô tả INSERT/UPDATE.'),
 ('Chi tiết, xác nhận, sau xóa','Mục 3.6–3.7: ảnh và mô tả SELECT/DELETE.'),
 ('Thống kê đủ 5 danh mục','Mục 3.8: ảnh và giải thích GROUP BY, phần trăm.'),
 ('Ảnh sau tắt hẳn, mở lại','Mục 3.9: force-stop tiến trình Android thực tế.'),
 ('Phần SQL riêng, đầy đủ code','Chương 4: CREATE, INSERT, SELECT, SUM, GROUP BY, UPDATE, DELETE.'),
])
p('Tên file báo cáo: B24DCCC102_TRANTUANHAI_BaoCao.docx. Nội dung mô tả đúng bản Flutter, không gọi widget là Activity Java hay Navigator là Intent. Khi bổ sung ảnh Database Inspector, giữ rõ chú thích nguồn và bảo đảm hình khớp database của dự án.')

# Đảm bảo mọi bảng có số cột/ô và ảnh được nhúng hợp lệ; Word có thể điều hướng theo Heading.
doc.save(OUT)
print(OUT)
print('Số hình:',fig_number)
print('Số ảnh nhúng riêng:',len(doc.inline_shapes))
print('Số trang chủ động:',1+len([p for p in doc.paragraphs if 'w:type="page"' in p._p.xml]))
