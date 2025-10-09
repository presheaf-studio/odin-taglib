package taglib

import "core:c"

when ODIN_OS == .Linux || ODIN_OS == .Darwin {@(require) foreign import stdcpp "system:stdc++"}
when ODIN_OS == .Windows {
    foreign import TagLib "windows/tag_c.lib"
} else when ODIN_OS == .Linux {
    when ODIN_ARCH == .arm64 {
        @(extra_linker_flags = "-lz")
        @(require)foreign import cpp "linux-arm64/libtag.a"
        foreign import TagLib "linux-arm64/libtag_c.a"
    } else {
        @(extra_linker_flags = "-lz")
        @(require)foreign import cpp "linux/libtag.a"
        foreign import TagLib "linux/libtag_c.a"
    }
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .arm64 {
        @(extra_linker_flags = "-lz")
        @(require)foreign import cpp "darwin-arm64/libtag.a"
        foreign import TagLib "darwin-arm64/libtag_c.a"
    }
}

_Dummy :: struct {
    dummy: int,
}

File :: _Dummy
Tag :: _Dummy
AudioProperties :: _Dummy
IOStream :: _Dummy

File_Type :: enum {
    MPEG,
    OggVorbis,
    FLAC,
    MPC,
    OggFlac,
    WavPack,
    Speex,
    TrueAudio,
    MP4,
    ASF,
    AIFF,
    WAV,
    APE,
    IT,
    Mod,
    S3M,
    XM,
    Opus,
    DSF,
    DSDIFF,
    SHORTEN,
}

ID3v2_Encoding :: enum {
    Latin1,
    UTF16,
    UTF16BE,
    UTF8,
}

/*
 * Types which can be stored in a Variant.
 * These correspond to TagLib::Variant::Type, but ByteVectorList, VariantList, VariantMap are not supported and will be
 * returned as their string representation.
 */
Variant_Type :: enum {
    Void,
    Bool,
    Int,
    UInt,
    LongLong,
    ULongLong,
    Double,
    String,
    StringList,
    ByteVector,
}

BOOL :: c.int
TRUE :: c.int(1)
FALSE :: c.int(0)

Variant_Union :: struct #raw_union {
    stringValue:     cstring,
    byteVectorValue: cstring,
    stringListValue: ^cstring,
    boolValue:       BOOL,
    intValue:        c.int,
    uIntValue:       c.uint,
    longLongValue:   c.longlong,
    uLongLongValue:  c.ulonglong,
    doubleValue:     c.double,
}

/*
 * Discriminated union used in complex property attributes.
 * `size` is only required for Variant_Type::ByteVector and must contain the number of bytes.
 */
Variant :: struct {
    type:  Variant_Type,
    size:  c.uint,
    value: Variant_Union,
}

// Complex properties consist of a NULL-terminated array of pointers to this structure.
Complex_Property_Attribute :: struct {
    key:   cstring,
    value: Variant,
}

Complex_Property_Picture_Data :: struct {
    mimeType:    cstring,
    description: cstring,
    pictureType: cstring,
    data:        cstring,
    size:        c.uint,
}

@(link_prefix = "taglib_", default_calling_convention = "c")
foreign TagLib {
    // Controls whether TagLib expects utf-8 (default) or Latin1 (ISO-8859-1) strings.
    set_strings_unicode :: proc(unicode: BOOL) ---
    // Controls tag string memory management by TagLib, enabled by default.
    set_string_management_enabled :: proc(management: BOOL) ---
    // Explicitly free a string returned from TagLib.
    free :: proc(pointer: rawptr) ---

    /***************
	* Stream API
    ****************/

    // Byte vector stream allocator.
    memory_iostream_new :: proc(data: [^]u8, size: c.uint) -> ^IOStream ---
    iostream_free :: proc(stream: ^IOStream) ---

    /***************
	* File API
    ****************/

    // Creates a File guessing its type.
    file_new :: proc(filename: cstring) -> ^File ---
    file_new_type :: proc(filename: cstring, type: File_Type) -> ^File ---
    file_new_iostream :: proc(stream: ^IOStream) -> ^File ---
    file_free :: proc(file: ^File) ---
    // Asserts file is open, readable, and has valid Tag or AudioProperties.
    file_is_valid :: proc(file: ^File) -> BOOL ---
    // Get managed File Tag.
    file_tag :: proc(file: ^File) -> ^Tag ---
    // Get managed File AudioProperties.
    file_audioproperties :: proc(file: ^File) -> ^AudioProperties ---
    // Commit changes.
    file_save :: proc(file: ^File) -> BOOL ---

    /***************
	* Tag API
    ****************/

    tag_title :: proc(tag: ^Tag) -> cstring ---
    tag_artist :: proc(tag: ^Tag) -> cstring ---
    tag_album :: proc(tag: ^Tag) -> cstring ---
    tag_comment :: proc(tag: ^Tag) -> cstring ---
    tag_genre :: proc(tag: ^Tag) -> cstring ---
    // Defaults to 0.
    tag_year :: proc(tag: ^Tag) -> c.uint ---
    // Defaults to 0.
    tag_track :: proc(tag: ^Tag) -> c.uint ---
    tag_set_title :: proc(tag: ^Tag, title: cstring) ---
    tag_set_artist :: proc(tag: ^Tag, artist: cstring) ---
    tag_set_album :: proc(tag: ^Tag, album: cstring) ---
    tag_set_comment :: proc(tag: ^Tag, comment: cstring) ---
    tag_set_genre :: proc(tag: ^Tag, genre: cstring) ---
    // Use 0 to clear the year.
    tag_set_year :: proc(tag: ^Tag, year: c.uint) ---
    // Use 0 to clear the track.
    tag_set_track :: proc(tag: ^Tag, track: c.uint) ---
    // Frees all of the strings that have been created by the tag.
    tag_free_strings :: proc() ---

    /***************
	* Audio Properties API
    ****************/

    // Length in seconds.
    audioproperties_length :: proc(audioProperties: ^AudioProperties) -> c.int ---
    audioproperties_bitrate :: proc(audioProperties: ^AudioProperties) -> c.int ---
    audioproperties_samplerate :: proc(audioProperties: ^AudioProperties) -> c.int ---
    audioproperties_channels :: proc(audioProperties: ^AudioProperties) -> c.int ---

    /***************
	* Special convenience ID3v2 functions
    ****************/

    id3v2_set_default_text_encoding :: proc(encoding: ID3v2_Encoding) ---

    /***************
    * Properties API
    ****************/

    property_set :: proc(file: ^File, prop: cstring, value: cstring) ---
    property_set_append :: proc(file: ^File, prop: cstring, value: cstring) ---
    property_keys :: proc(file: ^File) -> [^]cstring ---
    property_get :: proc(file: ^File, prop: cstring) -> [^]cstring ---
    property_free :: proc(props: ^cstring) ---

    /***************
    * Complex Properties API
    ****************/

    complex_property_set :: proc(file: ^File, key: cstring, value: ^[^]Complex_Property_Attribute) -> BOOL ---
    complex_property_set_append :: proc(file: ^File, key: cstring, value: ^[^]Complex_Property_Attribute) -> BOOL ---
    complex_property_keys :: proc(file: ^File) -> [^]cstring ---
    complex_property_get :: proc(file: ^File, key: cstring) -> ^[^][^]Complex_Property_Attribute ---
    picture_from_complex_property :: proc(properties: ^[^][^]Complex_Property_Attribute, picture: ^Complex_Property_Picture_Data) ---
    complex_property_free_keys :: proc(keys: ^cstring) ---
    complex_property_free :: proc(props: ^[^][^]Complex_Property_Attribute) ---
}
