unit flzma2;

interface

uses
  Classes, Windows, SysUtils;

{ * Error Codes * }
const
  FL2_error_no_error = 0;
  FL2_error_GENERIC = 1;
  FL2_error_internal = 2;
  FL2_error_corruption_detected = 3;
  FL2_error_checksum_wrong = 4;
  FL2_error_parameter_unsupported = 5;
  FL2_error_parameter_outOfBound = 6;
  FL2_error_lclpMax_exceeded = 7;
  FL2_error_stage_wrong = 8;
  FL2_error_init_missing = 9;
  FL2_error_memory_allocation = 10;
  FL2_error_dstSize_tooSmall = 11;
  FL2_error_srcSize_wrong = 12;
  FL2_error_canceled = 13;
  FL2_error_buffer = 14;
  FL2_error_timedOut = 15;
  FL2_error_maxCode = 20;
  { ***************************************
    *  Simple API
    ***************************************/

    /*! FL2_compress() :
    *  Compresses `src` content as a single LZMA2 compressed stream into already allocated `dst`.
    *  Call FL2_compressMt() to use > 1 thread. Specify nbThreads = 0 to use all cores.
    *  @return : compressed size written into `dst` (<= `dstCapacity),
    *            or an error code if it fails (which can be tested using FL2_isError()). * }

function FL2_compress(Dst: Pointer; DstCapacity: Integer; Src: Pointer;
  srcSize, compressionlevel: Integer): Integer; cdecl;
  external 'fast-lzma2.dll';

function FL2_compressMt(Dst: Pointer; DstCapacity: Integer; Src: Pointer;
  srcSize, compressionlevel: Integer; nbThreads: Integer = 0): Integer; cdecl;
  external 'fast-lzma2.dll';

{ *! FL2_decompress() :
  *  Decompresses a single LZMA2 compressed stream from `src` into already allocated `dst`.
  *  `compressedSize` : must be at least the size of the LZMA2 stream.
  *  `dstCapacity` is the original, uncompressed size to regenerate, returned by calling
  *  FL2_findDecompressedSize().
  *  Call FL2_decompressMt() to use > 1 thread. Specify nbThreads = 0 to use all cores. The stream
  *  must contain dictionary resets to use multiple threads. These are inserted during compression by
  *  default. The frequency can be changed/disabled with the FL2_p_resetInterval parameter setting.
  *  @return : the number of bytes decompressed into `dst` (<= `dstCapacity`),
  *            or an errorCode if it fails (which can be tested using FL2_isError()). * }

function FL2_decompress(Dst: Pointer; DstCapacity: Integer; Src: Pointer;
  compressedSize: Integer): Integer; cdecl; external 'fast-lzma2.dll';

function FL2_decompressMt(Dst: Pointer; DstCapacity: Integer; Src: Pointer;
  compressedSize: Integer; nbThreads: Integer = 0): Integer; cdecl;
  external 'fast-lzma2.dll';

{ *! FL2_findDecompressedSize()
  *  `src` should point to the start of a LZMA2 encoded stream.
  *  `srcSize` must be at least as large as the LZMA2 stream including end marker.
  *  A property byte is assumed to exist at position 0 in `src`. If the stream was created without one,
  *  subtract 1 byte from `src` when passing it to the function.
  *  @return : - decompressed size of the stream in `src`, if known
  *            - FL2_CONTENTSIZE_ERROR if an error occurred (e.g. corruption, srcSize too small)
  *   note 1 : a 0 return value means the stream is valid but "empty".
  *   note 2 : decompressed size can be very large (64-bits value),
  *            potentially larger than what local system can handle as a single memory segment.
  *            In which case, it's necessary to use streaming mode to decompress data.
  *   note 5 : If source is untrusted, decompressed size could be wrong or intentionally modified.
  *            Always ensure return value fits within application's authorized limits.
  *            Each application can set its own limits. * }

function FL2_findDecompressedSize(Src: Pointer; srcSize: Integer): int64; cdecl;
  external 'fast-lzma2.dll';

{ *======  Helper functions  ======* }
function FL2_compressBound(srcSize: Integer): Integer; cdecl;
  external 'fast-lzma2.dll';
{ *!< maximum compressed size in worst case scenario * }
function FL2_isError(code; Integer): Integer; cdecl; external 'fast-lzma2.dll';
{ *!< tells if a `size_t` function result is an error code * }
function FL2_isTimedOut(code; Integer): Integer; cdecl;
  external 'fast-lzma2.dll';
{ *!< tells if a `size_t` function result is the timeout code * }
function FL2_getErrorName(code; Integer): string; cdecl;
  external 'fast-lzma2.dll';
{ *!< provides readable string from an error code * }
function FL2_maxCLevel: Integer; cdecl; external 'fast-lzma2.dll';
{ *!< maximum compression level available * }
function FL2_maxHighCLevel: Integer; cdecl; external 'fast-lzma2.dll';
{ *!< maximum compression level available in high mode * }

{ *= Compression context
  *  When compressing many times, it is recommended to allocate a context just once,
  *  and re-use it for each successive compression operation. This will make workload
  *  friendlier for system's memory. The context may not use the number of threads requested
  *  if the library is compiled for single-threaded compression or nbThreads > FL2_MAXTHREADS.
  *  Call FL2_getCCtxThreadCount to obtain the actual number allocated. * }
type
  FL2_CCtx = Pointer;
//  FL2_CStream = pointer;
function FL2_createCCtx: FL2_CCtx; cdecl; external 'fast-lzma2.dll';
function FL2_createCCtxMt(nbThreads: Integer): FL2_CCtx; cdecl;
  external 'fast-lzma2.dll';
procedure FL2_freeCCtx(p: FL2_CCtx); cdecl; external 'fast-lzma2.dll';
function FL2_getCCtxThreadCount(p: FL2_CCtx): Integer; cdecl;
  external 'fast-lzma2.dll';

{ *! FL2_compressCCtx() :
  *  Same as FL2_compress(), but requires an allocated FL2_CCtx (see FL2_createCCtx()). * }

function FL2_compressCCtx(FL2_CCtx: Pointer; Dst: Pointer; DstCapacity: Integer;
  Src: Pointer; srcSize, compressionlevel: Integer): Integer; cdecl;
  external 'fast-lzma2.dll';

{ *! FL2_getCCtxDictProp() :
  *  Get the dictionary size property.
  *  Intended for use with the FL2_p_omitProperties parameter for creating a
  *  7-zip or XZ compatible LZMA2 stream. * }
function FL2_getCCtxDictProp(var p: FL2_CCtx): string;

{ *= Decompression context
  *  When decompressing many times, it is recommended to allocate a context only once,
  *  and re-use it for each successive decompression operation. This will make the workload
  *  friendlier for the system's memory.
  *  The context may not allocate the number of threads requested if the library is
  *  compiled for single-threaded compression or nbThreads > FL2_MAXTHREADS.
  *  Call FL2_getDCtxThreadCount to obtain the actual number allocated.
  *  At least nbThreads dictionary resets must exist in the stream to use all of the
  *  threads. Dictionary resets are inserted into the stream according to the
  *  FL2_p_resetInterval parameter used in the compression context. * }

type
  FL2_DCtx = Pointer;
function FL2_createDCtx: FL2_DCtx; cdecl; external 'fast-lzma2.dll';
function FL2_createDCtxMt(nbThreads: Integer): FL2_DCtx; cdecl;
  external 'fast-lzma2.dll';
procedure FL2_freeDCtx(p: FL2_DCtx); cdecl; external 'fast-lzma2.dll';
function FL2_getCCtxThreadCount(p: FL2_DCtx): Integer; cdecl;
  external 'fast-lzma2.dll';

{ *! FL2_decompressDCtx() :
  *  Same as FL2_decompress(), requires an allocated FL2_DCtx (see FL2_createDCtx()) * }

function FL2_decompressDCtx(FL2_DCtx: Pointer; Dst: Pointer;
  DstCapacity: Integer; Src: Pointer; srcSize: Integer): Integer; cdecl;
  external 'fast-lzma2.dll';

{ ****************************
  *  Streaming
  **************************** }

type
  FL2_inBuffer = packed record
    Src: Pointer;
    Size: Integer;
    Pos: Integer;
  end;

type
  FL2_OutBuffer = packed record
    Dst: Pointer;
    Size: Integer;
    Pos: Integer;
  end;

type
  FL2_dictBuffer = packed record
    Dst: Pointer;
    Size: Integer;
  end;

type
  FL2_CBuffer = packed record
    Src: Pointer;
    Size: Integer;
  end;

  { *-***********************************************************************
    *  Streaming compression
    *
    *  A FL2_CStream object is required to track streaming operation.
    *  Use FL2_createCStream() and FL2_freeCStream() to create/release resources.
    *  FL2_CStream objects can be reused multiple times on consecutive compression operations.
    *  It is recommended to re-use FL2_CStream in situations where many streaming operations will be done
    *  consecutively, since it will reduce allocation and initialization time.
    *
    *  Call FL2_createCStreamMt() with a nonzero dualBuffer parameter to use two input dictionary buffers.
    *  The stream will not block on FL2_compressStream() and continues to accept data while compression is
    *  underway, until both buffers are full. Useful when I/O is slow.
    *  To compress with a single thread with dual buffering, call FL2_createCStreamMt with nbThreads=1.
    *
    *  Use FL2_initCStream() on the FL2_CStream object to start a new compression operation.
    *
    *  Use FL2_compressStream() repetitively to consume input stream.
    *  The function will automatically update the `pos` field.
    *  It will always consume the entire input unless an error occurs or the dictionary buffer is filled,
    *  unlike the decompression function.
    *
    *  The radix match finder allows compressed data to be stored in its match table during encoding.
    *  Applications may call streaming compression functions with output == NULL. In this case,
    *  when the function returns 1, the compressed data must be read from the internal buffers.
    *  Call FL2_getNextCompressedBuffer() repeatedly until it returns 0.
    *  Each call returns buffer information in the FL2_inBuffer parameter. Applications typically will
    *  passed this to an I/O write function or downstream filter.
    *  Alternately, applications may pass an FL2_outBuffer object pointer to receive the output. In this
    *  case the return value is 1 if the buffer is full and more compressed data remains.
    *
    *  FL2_endStream() instructs to finish a stream. It will perform a flush and write the LZMA2
    *  termination byte (required). Call FL2_endStream() repeatedly until it returns 0.
    *
    *  Most functions may return a size_t error code, which can be tested using FL2_isError().
    *
    * ******************************************************************* }

type
FL2_CStream = class;
implementation

end.
