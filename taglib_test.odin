package taglib

// import "core:os"
import "core:fmt"
import "core:strings"
import "core:testing"

@(test)
parse_md :: proc(t: ^testing.T) {
    // os.open()
    b: strings.Builder
    strings.builder_init(&b)
    strings.write_string(&b, "assets/bit.flac")
    fname, _ := strings.to_cstring(&b)
    tfile := file_new(fname)
    defer file_free(tfile)
    tag := file_tag(tfile)
    defer tag_free_strings()
    title := strings.clone_from_cstring(tag_title(tag))
    track := u64(tag_track(tag))
    album := strings.clone_from_cstring(tag_album(tag))
    comment := strings.clone_from_cstring(tag_comment(tag))
    genre := strings.clone_from_cstring(tag_genre(tag))
    year := u64(tag_year(tag))
    fmt.printfln(
        "Title: %v\nTrack: %v\nAlbum: %v\nComment: %v\nGenre: %v\nYear: %v",
        title,
        track,
        album,
        comment,
        genre,
        year,
    )
}
