# Kiểm kê nội dung mẫu và ảnh bìa

## Catalog demo hiện tại (2026-11-19)

`lib/data/sample_books.dart` hiện khai báo **11 tác phẩm hư cấu demo** với
ID `1`–`11` giữ nguyên. Tên tác giả, mô tả và preview ngắn dưới đây được
viết mới trực tiếp cho dự án trong lần thay catalog này, không trích từ
tác phẩm, bản dịch hoặc trang ngoài. `lib/data/categories.dart` giữ 13 ID và
nhãn thể loại thông thường; 13 câu mô tả danh mục đã được viết lại cho dự án.
Đây là ghi nhận provenance của phần source hiện tại, không tự gắn một giấy
phép bên ngoài, không khẳng định quyền độc quyền hoặc kết luận pháp lý.

| ID | Tác phẩm demo / tác giả hư cấu | Vai trò | `coverRef` |
| --- | --- | --- | --- |
| `1` | *The Lantern Between Towns* — Mira Vale | metadata, mô tả, preview | `generated:midnight` |
| `2` | *The Case of the Missing Mapmaker* — Theo Finch | metadata, mô tả, preview | `generated:lagoon` |
| `3` | *The Cloud Orchard* — Nia Sol | metadata, mô tả, preview | `generated:coral` |
| `4` | *Letters from Cedar Pier* — Mira Vale | metadata, mô tả, preview | `generated:sunrise` |
| `5` | *Tomorrow's Quiet Signal* — Ivo Rell | metadata, mô tả, preview | `generated:forest` |
| `6` | *The Last Ferry at Low Tide* — Sera Quill | metadata, mô tả, preview | `generated:plum` |
| `7` | *The Garden of Glass Moons* — Nia Sol | metadata, mô tả, preview | `generated:midnight` |
| `8` | *The River Keeps Its Names* — Ansel Reed | metadata, mô tả, preview | `generated:lagoon` |
| `9` | *Two Shadows at Noon* — Theo Finch | metadata, mô tả, preview | `generated:coral` |
| `10` | *The Archive of Small Weather* — Ivo Rell | metadata, mô tả, preview | `generated:forest` |
| `11` | *The Kite Makers' Trail* — Sera Quill | metadata, mô tả, preview | `generated:sunrise` |

Các bìa hiện tại do `lib/widgets/book_cover.dart` vẽ từ màu, hình học và chữ
trong metadata sách; không có file JPG, ảnh mạng hoặc ảnh do dịch vụ ngoài
cung cấp trong luồng bìa. Sáu mã kiểu bìa hợp lệ là `generated:midnight`,
`generated:lagoon`, `generated:coral`, `generated:forest`, `generated:plum`
và `generated:sunrise`. `pubspec.yaml` không còn khai báo thư mục bìa.
Nếu một document Firestore cũ còn `coverRef` dạng đường dẫn JPG, widget hiện
bìa vẽ dự phòng; Admin có thể chọn mã mới. Cần migration riêng cho catalog đã
được đưa vào Firebase development. Không có migration hoặc triển khai Firebase
trong lần thay này.

**Trạng thái lịch sử đã làm sạch:** Toàn bộ 11 tệp JPG cũ (`assets/images/book_covers/`)
và các đoạn văn bản mẫu cũ trong `lib/data/sample_books.dart` đã được loại bỏ hoàn
toàn khỏi mọi commit trong lịch sử của bản sao này bằng `git-filter-repo`. Toàn bộ
catalog từ commit đầu tiên đến HEAD chỉ chứa metadata và preview hư cấu do dự án tự biên soạn.
Bảng kiểm kê bên dưới được lưu lại nhằm mục đích đối chiếu kỹ thuật lịch sử.

## Kiểm kê lịch sử trước khi thay catalog

Ngày kiểm tra: **2026-11-19**. Phạm vi: `lib/data/sample_books.dart`,
`lib/data/categories.dart`, toàn bộ 11 tệp trong
`assets/images/book_covers/`, đường dẫn asset trong `pubspec.yaml`, source Dart
và README **trước khi thay catalog**. Bảng sau lưu bằng chứng về nội dung cũ
trong Git history; không mô tả catalog đang chạy. Tài liệu này **không** cấp
quyền sử dụng hoặc kết luận repo có thể công bố.

## Cách đọc trạng thái

- **Verified**: có nguồn trực tiếp, đúng phiên bản asset trong repo và bằng chứng
  quyền tái sử dụng/attribution cho phạm vi phát hành dự kiến.
- **Unverified**: xác định được tác phẩm hoặc manh mối nguồn, nhưng thiếu nguồn
  của đúng bản sao, chủ quyền, điều kiện tái sử dụng hoặc phạm vi lãnh thổ.
- **Needs replacement**: có sai lệch nội dung/ảnh so với tác phẩm được gán hoặc
  nội dung sai rõ ràng; chủ repo cần thay thế/gỡ khỏi bản public sau khi quyết
  định. Không tự xóa hoặc thay file trong lần kiểm kê này.

Trang [Project Gutenberg về quyền sử dụng](https://www.gutenberg.org/policy/permission)
và [điều khoản](https://www.gutenberg.org/policy/terms_of_use) nêu rõ đánh giá
public domain của họ chủ yếu theo luật Hoa Kỳ, không bảo đảm tình trạng ở quốc
gia khác. Một tác phẩm gốc cũ, bản dịch, thiết kế bìa, hình minh họa và bản
biên tập là các đối tượng cần kiểm tra riêng. Link sách ở Gutenberg dưới đây
chỉ đối chiếu tác phẩm/đoạn tương tự và tình trạng **bản Gutenberg tại Hoa Kỳ**;
chúng không chứng minh nguồn gốc hoặc quyền của đúng chuỗi văn bản/ảnh đang
đóng gói. Hiện không tìm thấy license, hồ sơ mua/được cấp phép, thông tin tác
giả ảnh hay attribution cho các tệp ảnh trong repo. Git history chỉ cho thấy
chúng được thêm ở commit `3fb00f2` ngày 2025-09-26, không ghi nguồn.

## Ảnh bìa đóng gói

Mọi hàng có vai trò **cover**, ngày kiểm tra **2026-11-19**. Cột bằng chứng
giúp nhận diện tác phẩm trên ảnh, **không phải giấy phép của chính tệp JPG**.
Với cả 11 ảnh, license/điều kiện attribution của bản sao trong repo: **chưa rõ**.

| Tệp / ID sách | Tác phẩm trên ảnh; creator/rights holder biết được | Nguồn/bằng chứng | Trạng thái | Việc chủ repo cần làm |
| --- | --- | --- | --- | --- |
| `assets/images/book_covers/romeo_and_juliet.jpg` / `1` | Ảnh thiết kế bìa *Romeo and Juliet* dạng Maple Classics; Maple Press là nhà xuất bản, tác giả thiết kế/chủ quyền đúng JPG chưa rõ | [Maple Press, ấn bản Romeo and Juliet](https://www.maplepress.co.in/products/romeo-and-juliet); đối chiếu hình trực quan, chưa chứng minh cùng file | Unverified | Tìm nguồn chính xác và giấy phép cho ảnh; nếu không có, thay bằng bìa được cấp phép. |
| `assets/images/book_covers/adventure_of_sherlock_holmes.jpg` / `2` | Bìa minh họa *The Adventures of Sherlock Holmes*; họa sĩ/nhà xuất bản/chủ quyền chưa xác định | [Gutenberg, tác phẩm](https://www.gutenberg.org/ebooks/1661) chỉ xác nhận văn bản, không cấp quyền bìa này | Unverified | Truy xuất đúng ấn bản và bằng chứng quyền thiết kế/ảnh bìa hoặc thay. |
| `assets/images/book_covers/alcie_adventure_in_wonderland.jpg` / `3` | Bìa mang nhãn Puffin Classics, *Alice's Adventures in Wonderland*; họa sĩ/chủ quyền đúng ảnh chưa xác định | [Penguin, ấn bản Alice](https://www.penguin.co.uk/books/59520/alices-adventures-in-wonderland-by-carroll-lewis/9780141924656); trang ấn bản không cấp quyền tái sử dụng JPG này | Unverified | Xác định đúng artwork/giấy phép; sửa tên file sai chính tả chỉ sau quyết định của chủ repo. |
| `assets/images/book_covers/first_love.jpg` / `4` | Ảnh ghi *Love at First Book* của Jenn McKinlay, **không phải** *First Love* của Turgenev; nhà xuất bản Berkley/Penguin Random House | [Trang sách của nhà xuất bản](https://www.penguinrandomhouse.com/books/705384/love-at-first-book-by-jenn-mckinlay/); đối chiếu chữ trên ảnh | Needs replacement | Gỡ khỏi bản phát hành hoặc thay bằng ảnh đúng tác phẩm có quyền rõ ràng; không dùng ảnh này cho Turgenev. |
| `assets/images/book_covers/tales_of_space_ad_time.jpg` / `5` | Ảnh ghi *New Tales of Space and Time*, biên tập Raymond J. Healy, **khác** tập truyện H. G. Wells; chủ quyền thiết kế chưa rõ | Chữ trên ảnh; [Gutenberg, tác phẩm Wells](https://www.gutenberg.org/ebooks/27365) xác nhận nhan đề khác | Needs replacement | Thay ảnh đúng tác phẩm và có bằng chứng quyền; không suy từ nhan đề gần giống. |
| `assets/images/book_covers/the_most dangerous_game.jpg` / `6` | Poster phim *The Most Dangerous Game* (RKO, 1932), **không phải** bìa truyện Richard Connell; quyền poster/bản sao chưa rõ | Tên diễn viên và tín dụng phim hiện trên ảnh; [Gutenberg Canada, truyện Connell](https://mail.gutenberg.ca/ebooks/connellr-mostdangerousgame/connellr-mostdangerousgame-00-h.html) chỉ chứng minh tác phẩm văn học | Needs replacement | Thay poster bằng ảnh có nguồn và quyền kiểm chứng được. |
| `assets/images/book_covers/the_blazing_world.jpg` / `7` | Bìa *The Blazing World* của **Siri Hustvedt**, không phải Margaret Cavendish; Simon & Schuster là nhà xuất bản ấn bản đối chiếu | [Simon & Schuster, tiểu thuyết Hustvedt](https://www.simonandschuster.com/books/The-Blazing-World/Siri-Hustvedt/9781476747248); đối chiếu chữ trên ảnh | Needs replacement | Thay ảnh đúng tác phẩm Cavendish và có quyền rõ ràng. |
| `assets/images/book_covers/cleopatra.jpg` / `8` | Bìa *Cleopatra VII: Daughter of the Nile* của **Kristiana Gregory**, không phải *Cleopatra* của H. Rider Haggard; Scholastic là nhà xuất bản | [Scholastic, Royal Diaries: Cleopatra VII](https://www.scholastic.ca/our-books/book/royal-diaries-the-cleopatra-vii-9780590819756); đối chiếu chữ trên ảnh | Needs replacement | Thay ảnh đúng tác phẩm và được cấp phép. |
| `assets/images/book_covers/the_double.jpg` / `9` | Bìa *Double Indemnity* của **James M. Cain**, không phải *The Double* của Dostoyevsky; chủ quyền đúng ấn bản chưa rõ | Chữ trên ảnh; [bản lưu trữ The Double](https://archive.org/details/dostoyevsky_fyodor_1821_1881_double) không liên quan bìa này | Needs replacement | Thay ảnh đúng tác phẩm và được cấp phép. |
| `assets/images/book_covers/all_in_the_mind.jpg` / `10` | Bìa *The Mind Within the Brain* của **A. David Redish**, không phải *All In The Mind* của Henderson; chủ quyền bìa chưa rõ | [Trang sách của nhóm tác giả](https://redishlab.umn.edu/books); [Gutenberg, Henderson](https://www.gutenberg.org/ebooks/32434) xác nhận tác phẩm khác | Needs replacement | Thay ảnh đúng tác phẩm và được cấp phép. |
| `assets/images/book_covers/harry_potter.jpg` / `11` | Bìa thương mại mang nhãn Bloomsbury cho *Harry Potter and the Philosopher's Stone* của J. K. Rowling; họa sĩ/chủ quyền đúng ảnh chưa xác định | [Bloomsbury, ấn bản Harry Potter](https://www.bloomsbury.com/uk/harry-potter-and-the-philosophers-stone-9781526602381/) xác nhận sách, không cấp quyền tái sử dụng JPG này | Unverified | Xin phép chủ quyền đúng artwork hoặc thay/gỡ trước khi public; kiểm tra thêm quyền nhãn hiệu/hình ảnh. |

## Preview và mô tả sách trong `lib/data/sample_books.dart`

Mỗi dòng bao phủ **hai chuỗi riêng**: `content` (preview) và `description`
(mô tả). Ngày kiểm tra mọi dòng: **2026-11-19**. `content` chỉ là đoạn
preview, có chỗ được cắt bằng `...`; app không chứa toàn văn sách. Với mọi
preview/mô tả, repo chưa ghi nguồn đã chép/soạn, license riêng của đúng bản
văn bản hoặc yêu cầu attribution. Link dưới đây chứng minh nhận diện/đối chiếu,
không tự động xác minh quyền phát hành của chuỗi trong source.

| ID; tác phẩm/creator | Preview: nguồn đối chiếu, điều kiện, trạng thái | Mô tả: nguồn/điều kiện, trạng thái | Việc chủ repo cần làm |
| --- | --- | --- | --- |
| `1` *Romeo and Juliet* — William Shakespeare | Mở đầu Prologue/Act I khớp [Gutenberg #1513](https://www.gutenberg.org/ebooks/1513), bản đó ghi public domain **tại Hoa Kỳ**; đúng bản chép/biên tập trong repo chưa có hồ sơ. **Unverified** | Tóm tắt tác phẩm, nguồn câu chữ/license chưa rõ. **Unverified** | Lưu nguồn chính xác của preview/mô tả, cách cắt đoạn và điều kiện dùng tại khu vực phát hành. |
| `2` *The Adventures of Sherlock Holmes* — Arthur Conan Doyle | Đầu “A Scandal in Bohemia” đối chiếu [Gutenberg #1661](https://www.gutenberg.org/ebooks/1661), bản đó ghi public domain tại Hoa Kỳ; nguồn đúng bản chép chưa rõ. **Unverified** | Mô tả 12 truyện, nguồn câu chữ/license chưa rõ. **Unverified** | Sửa metadata nhan đề đang thiếu `s` (*Adventure* → *Adventures*) sau khi chủ repo duyệt; xác minh nguồn preview/mô tả. |
| `3` *Alice's Adventures in Wonderland* — Lewis Carroll / Charles L. Dodgson | Đầu chương I đối chiếu [Gutenberg #11](https://www.gutenberg.org/ebooks/11), tình trạng nêu cho Hoa Kỳ; nguồn đúng bản chép chưa rõ. **Unverified** | Tóm tắt tên/tác giả/năm, nguồn câu chữ/license chưa rõ. **Unverified** | Ghi nguồn từng chuỗi và phạm vi quyền cần dùng. |
| `4` *First Love* — Ivan Turgenev; **người dịch chưa xác định** | Cùng tình tiết với [Gutenberg #9911, bản dịch Constance Garnett](https://www.gutenberg.org/ebooks/9911), nhưng câu chữ khác; không gán bản dịch trong repo cho Garnett. **Unverified** | Nguồn câu chữ/license chưa rõ. **Unverified** | Truy ra bản dịch chính xác và quyền của bản dịch/đoạn cắt; không suy quyền từ nguyên tác Nga. |
| `5` *Tales of Space and Time* — H. G. Wells | Đoạn đầu “The Crystal Egg” đối chiếu [Gutenberg #27365](https://www.gutenberg.org/ebooks/27365), tình trạng nêu cho Hoa Kỳ; nguồn đúng bản chép chưa rõ. **Unverified** | Tóm tắt tập truyện, nguồn câu chữ/license chưa rõ. **Unverified** | Ghi nguồn chính xác và điều kiện attribution/phát hành. |
| `6` *The Most Dangerous Game* — Richard Connell | Đoạn hội thoại đầu đối chiếu [Gutenberg Canada, văn bản truyện](https://mail.gutenberg.ca/ebooks/connellr-mostdangerousgame/connellr-mostdangerousgame-00-h.html); chưa chứng minh đúng bản sao và quyền ở mọi nước. **Unverified** | Nguồn câu chữ/license chưa rõ. **Unverified** | Xác minh nguồn bản chép, điều kiện ở từng vùng phát hành và nguồn mô tả. |
| `7` *The Blazing World* — Margaret Cavendish | Đầu tác phẩm gần [Gutenberg #51783](https://www.gutenberg.org/ebooks/51783), nhưng source hiện đại hóa chính tả; nguồn bản biên tập chưa rõ. **Unverified** | Tóm tắt năm/nhan đề, nguồn câu chữ/license chưa rõ. **Unverified** | Xác minh đúng bản biên tập và điều kiện; ghi rõ attribution nếu dùng bản lưu trữ. |
| `8` *Cleopatra* — H. Rider Haggard | [Gutenberg #2769](https://www.gutenberg.org/ebooks/2769) xác nhận tác phẩm, nhưng chưa tìm được nguồn trực tiếp của đoạn `PROLOGUE` hiện tại; không coi là trích đúng sách. **Unverified** | Tóm tắt tác phẩm, nguồn câu chữ/license chưa rõ. **Unverified** | Đối chiếu đoạn với ấn bản xác định; thay preview nếu không truy được nguồn. |
| `9` *The Double* — Fyodor Dostoyevsky; **người dịch chưa xác định** | Đầu tác phẩm giống bản dịch Constance Garnett nhưng tên riêng/câu chữ khác; [bản in lưu trữ](https://archive.org/details/dostoyevsky_fyodor_1821_1881_double) cần đối chiếu đúng ấn bản trước khi ghi quyền. **Unverified** | Tóm tắt tác phẩm, nguồn câu chữ/license chưa rõ. **Unverified** | Xác định bản dịch/biên tập thực tế, quyền bản dịch và nguồn mô tả. |
| `10` *All In The Mind* — Gene L. Henderson | Preview về “Dr. Sarah Chen / Marcus Webb” **không phải** mở đầu truyện về Mel Carlson trong [Gutenberg #32434](https://www.gutenberg.org/cache/epub/32434/pg32434-images.html); tác giả đoạn repo chưa rõ. **Needs replacement** | Mô tả khoa học viễn tưởng rất chung, không rõ nguồn; **Unverified** | Gỡ/thay preview sai gán tác giả bằng đoạn có nguồn/giấy phép rõ hoặc nội dung tự viết có hồ sơ. |
| `11` *Harry Potter and the Philosopher's Stone* — J. K. Rowling | `CHAPTER I. A Little Life` sai: [trang chính thức Harry Potter](https://www.harrypotter.com/features/analysing-the-first-chapter-of-harry-potter-and-the-philosophers-stone) ghi chương đầu “The Boy Who Lived”. **Needs replacement** | Câu mô tả dở dang ở “and Rowling”; nguồn/license chưa rõ. **Needs replacement** | Sửa nhan đề đang thiếu khoảng trắng trước `Stone`, thay preview/mô tả bằng thông tin đúng và được phép, hoặc bỏ mục khỏi bản public. |

Lưu ý: hàng `9` hiện chỉ có link đối chiếu tác phẩm, không chứng minh bản
dịch; không dùng link đó như giấy phép của đoạn preview. Tương tự, nội dung
preview tự viết hoặc sửa từ bản khác cũng cần hồ sơ người tạo/điều kiện dùng.

## Danh mục và asset ngoài bảng trên

`lib/data/categories.dart` có 13 ID/nhãn/mô tả ngắn: `short_stories`,
`science_fiction`, `action_adventure`, `fiction`, `classic`, `fantasy`,
`mystery`, `romance`, `drama`, `children`, `thriller`, `historical_fiction`,
`psychology`. Vai trò: nhãn UI và mô tả danh mục; tác giả/source/license của
câu mô tả chưa được ghi trong repo. Cả **13: Unverified**, kiểm tra 2026-11-19.
Chủ repo cần xác nhận chúng là câu do nhóm dự án tự viết hoặc lưu nguồn/điều
kiện sử dụng trước khi public. Những nhãn thể loại thông thường không phải
bằng chứng về quyền của câu mô tả.

`pubspec.yaml` trước khi thay catalog chỉ đóng gói thư mục
`assets/images/book_covers/`; cả 11 JPG khi đó tồn tại và được tham chiếu bởi
`coverImage` trong catalog và danh sách asset của Admin. Source khi đó dùng
`Image.asset` cho bìa. Không thấy file icon,
font, âm thanh hay hình khác do repo đóng gói. `uses-material-design: true` và
`cupertino_icons` là asset từ Flutter/package, không phải file do repo cung cấp;
kiểm tra license của dependency riêng khi chuẩn bị phát hành. README có đường
dẫn minh họa `assets/images/book_covers/example.jpg`, **không phải file thật**.

## Quyết định trước khi public

1. Tìm hồ sơ gốc/permission của **đúng 11 JPG**; ít nhất 7 bìa đang gán sai
   tác phẩm và cần thay/gỡ trong bản public. Không lấy ảnh từ trang kết quả
   tìm kiếm hoặc mirror làm bằng chứng quyền.
2. Xác định nguồn và bản dịch/biên tập của từng preview, cùng người viết và
   điều kiện dùng mô tả. Xử lý trước hai preview sai ở ID `10`, `11`, mô tả
   dở dang ID `11` và nhan đề sai ID `2`, `11`.
3. Xác định quốc gia/nền tảng phát hành dự kiến; kiểm tra quyền riêng cho từng
   bản dịch, ảnh bìa, hình minh họa và điều kiện attribution. Nếu dùng văn bản
   Gutenberg, ghi URL item, phiên bản, ngày tải, license/điều kiện áp dụng và
   cách xử lý tên/trademark Gutenberg. Cần chủ repo hoặc người có thẩm quyền
   quyết định; bảng này không thay thế tư vấn pháp lý.

**Tổng kiểm kê:** 11 ảnh bìa: 0 Verified, 4 Unverified, 7 Needs replacement.
11 preview: 0 Verified, 9 Unverified, 2 Needs replacement. 11 mô tả sách:
0 Verified, 10 Unverified, 1 Needs replacement. 13 mô tả danh mục:
0 Verified, 13 Unverified, 0 Needs replacement. Tổng 46 đơn vị nội dung:
**0 Verified, 36 Unverified, 10 Needs replacement**.
