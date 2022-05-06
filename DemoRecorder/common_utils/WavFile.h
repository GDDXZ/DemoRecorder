////////////////////////////////////////////////////////////////////////////////
///
/// Classes for easy reading & writing of WAV sound files.
///
/// For big-endian CPU, define BIG_ENDIAN during compile-time to correctly
/// parse the WAV files with such processors.
///
/// Admittingly, more complete WAV reader routines may exist in public domain, but
/// the reason for 'yet another' one is that those generic WAV reader libraries are
/// exhaustingly large and cumbersome! Wanted to have something simpler here, i.e.
/// something that's not already larger than rest of the SoundTouch/SoundStretch program...
///
/// Author        : Copyright (c) Olli Parviainen
/// Author e-mail : oparviai 'at' iki.fi
/// SoundTouch WWW: http://www.surina.net/soundtouch
///
////////////////////////////////////////////////////////////////////////////////
//
// Last changed  : $Date: 2014-10-05 19:20:24 +0300 (Sun, 05 Oct 2014) $
// File revision : $Revision: 4 $
//
// $Id: WavFile.h 200 2014-10-05 16:20:24Z oparviai $
//
////////////////////////////////////////////////////////////////////////////////
//
// License :
//
//  SoundTouch audio processing library
//  Copyright (c) Olli Parviainen
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
////////////////////////////////////////////////////////////////////////////////

#ifndef WAVFILE_H
#define WAVFILE_H

#include <stdio.h>
#include <assert.h>
#include <string.h>




#ifndef uint
typedef unsigned int uint;
#endif


/// WAV audio file 'riff' section header
typedef struct
{
    char riff_char[4];
    int  package_len;
    char wave[4];
} WavRiff;

/// WAV audio file 'format' section header
typedef struct
{
    char  fmt[4];
    int   format_len;       //格式块长度（一般=16，若=18表示最后有2字节附加信息）,格式块长度不包括格式标志4字节以及块长度本身所占用的4个字节
    short fixed;            //格式类别（值＝1表示编码方式为PCMμ律编码）3:表示是浮点类型未压缩的数据，数据位深由bits_per_sample指定
    short channel_number;   //声道数（单声道＝1，双声音＝2）
    int   sample_rate;      //采样率
    int   byte_rate;        //比特率 =  sample_rate * byte_per_sample
    short byte_per_sample;  //每个通道下采样点的字节数的和，跟通道有关
    short bits_per_sample;  //每个采样点的位深，跟通道无关
    //如果有2字节的附加信息，则在读取时会忽略
} WavFormat;

//wav文件中section标记块的基本结构，常见标记块有fact、PEAK等等
//----------------------------------------------
//偏移量  名称    字节数 类型    说明
//----------------------------------------------
//00      块标志   4     字符    由ASCII字符组成
//04      块长度   4     长整型
//08      块内容                 数据
//----------------------------------------------

/// WAV audio file 'fact' section header
typedef struct
{
    char  fact_field[4];
    int   fact_len;
    uint  fact_sample_len;
} WavFact;

/// WAV audio file 'data' section header
typedef struct
{
    char  data_field[4];
    uint  data_len;
} WavData;


/// WAV audio file header
typedef struct
{
    WavRiff   riff;
    WavFormat format;
    WavFact   fact;
    WavData   data;
} WavHeader;


/// Base class for processing WAV audio files.
class WavFileBase
{
private:
    /// Conversion working buffer;
    char *convBuff;
    int convBuffSize;
protected:
    WavFileBase();
    virtual ~WavFileBase();

    /// Get pointer to conversion buffer of at min. given size
    void *getConvBuffer(int sizeByte);
};

/// Class for reading WAV audio files.
class WavInFile : protected WavFileBase
{
private:
    /// File pointer.
    FILE *fptr;

    /// Position within the audio stream
    long position;

    /// Counter of how many bytes of sample data have been read from the file.
    long dataRead;

    /// WAV header information
    WavHeader header;
    
    /// Wav Data start byte position in file, when seek ,we should seek reletive to the data start posion
    long dataStartPosition=0;
    
    /// Init the WAV file stream
    void init();

    /// Read WAV file headers.
    /// \return zero if all ok, nonzero if file format is invalid.
    int readWavHeaders();

    /// Checks WAV file header tags.
    /// \return zero if all ok, nonzero if file format is invalid.
    int checkCharTags() const;

    /// Reads a single WAV file header block.
    /// \return zero if all ok, nonzero if file format is invalid.
    int readHeaderBlock();

    /// Reads WAV file 'riff' block
    int readRIFFBlock();
private:
    /// 是否读取的是pcm文件
    bool isReadPcmFile=false;
    int _readPcmFile(FILE *file ,int sampleRate,int bits,int channels);
public:
    /// Constructor: Opens the given WAV or pcm file. If the file can't be opened,
    /// throws 'runtime_error' exception.
    /// 可以读取pcm文件或wav文件，如果是wav文件则忽略后面三个参数，如果pcm文件则必须传后面三个参数
    /// 通过filename的后缀名是否是.wav来区分是写wav文件还是写pcm文件
    WavInFile(const char *filename,      ///< wav or pcm file name
                int sampleRate=0,          ///< Sample rate (e.g. 44100 etc)
                int bits=0,                ///< Bits per sample (8 or 16 bits or 32bits)
                int channels=0 );          ///< Number of channels (1=mono, 2=stereo));

    /// use opened ftr to read and wav or pcm file
    /// 如果打开的是wav文件则后面三个参数可以不用传，如果是pcm文件则必须传
    WavInFile( FILE *file,                /// opened fileptr
                int sampleRate=0,          ///< Sample rate (e.g. 44100 etc)
                int bits=0,                ///< Bits per sample (8 or 16 bits or 32bits)
                int channels=0 );            ///< Number of channels (1=mono, 2=stereo)););

    /// Destructor: Closes the file.
    ~WavInFile();

    /// Rewind to beginning of the file
    void rewind();
    
    /// Seek to samplesPosition to read data
    int seek(long samplesPosition);
    
    /// Get sample rate.
    uint getSampleRate() const;

    /// Get number of bits per sample, i.e. 8 or 16.
    uint getNumBits() const;

    /// Get sample data size in bytes. Ahem, this should return same information as
    /// 'getBytesPerSample'...
    uint getDataSizeInBytes() const;

    /// Get total number of samples in file. 相当于跟通道无关的frame数
    uint getNumSamples() const;

    /// Get number of bytes per audio sample (e.g. 16bit stereo = 4 bytes/sample)
    uint getBytesPerSample() const;

    /// Get number of audio channels in the file (1=mono, 2=stereo)
    uint getNumChannels() const;

    /// Get the audio file length in milliseconds
    uint getLengthMS() const;

    /// Returns how many milliseconds of audio have so far been read from the file
    ///
    /// \return elapsed duration in milliseconds
    uint getElapsedMS() const;

    /// Reads audio samples from the WAV file. This routine works only for 8 bit samples.
    /// Reads given number of elements from the file or if end-of-file reached, as many
    /// elements as are left in the file.
    ///
    /// \return Number of 8-bit integers read from the file.
    int read(unsigned char *buffer, int maxElems);

    /// Reads audio samples from the WAV file to 16 bit integer format. Reads given number
    /// of elements from the file or if end-of-file reached, as many elements as are
    /// left in the file.
    ///
    /// \return Number of 16-bit integers read from the file.
    int read(short *buffer,     ///< Pointer to buffer where to read data.
             int maxElems       ///< Size of 'buffer' array (number of array elements).
            );

    /// Reads audio samples from the WAV file to floating point format, converting
    /// sample values to range [-1,1[. Reads given number of elements from the file
    /// or if end-of-file reached, as many elements as are left in the file.
    /// Notice that reading in float format supports 8/16/24/32bit sample formats.
    ///
    /// \return Number of elements read from the file.
    int read(float *buffer,     ///< Pointer to buffer where to read data.
             int maxElems       ///< Size of 'buffer' array (number of array elements).
            );
    /// Reads audio samples form the wave file at time belone to  [startTime endTime] to floating point format
    /// time is in milllion second
    int read(float *buffer,
             long startTime,
             long endTime,
             int maxElems);
    int read(short *buffer, long startTime, long endTime, int maxElems);

    //read audio sampl from startIndex to endIndex, the index is in short cnt;
    int read(short *buffer, long startSampleIndex, long endSampleIndex);

    /// Check end-of-file.
    ///
    /// \return Nonzero if end-of-file reached.
    int eof() const;

    /// check 打开文件是否为空, true表示成功，false表示失败
    bool isOpend();
};


/// Class for writing WAV audio files.
class WavOutFile : protected WavFileBase
{
private:
    /// Pointer to the WAV file
    FILE *fptr;

    /// WAV file header data.
    WavHeader header;

    /// Counter of how many bytes have been written to the file so far.
    int bytesWritten;

    /// Fills in WAV file header information.
    void fillInHeader(const uint sampleRate, const uint bits, const uint channels);

    /// Finishes the WAV file header by supplementing information of amount of
    /// data written to file etc
    void finishHeader();

    /// Writes the WAV file header.
    void writeHeader();

    /// 是否写文件时只写pcm数据不写文件头
    bool writePcmOnly=false;

public:
    /// Constructor: Creates a new WAV or pcm file. Throws a 'runtime_error' exception
    /// if file creation fails.通过后缀名是否是.wav来区分是写wav文件还是写pcm文件
    WavOutFile(const char *fileName,    ///< Filename
               int sampleRate,          ///< Sample rate (e.g. 44100 etc)
               int bits,                ///< Bits per sample (8 or 16 bits or 32bits)
               int channels            ///< Number of channels (1=mono, 2=stereo)
              );

    WavOutFile(FILE *file, int sampleRate, int bits, int channels,bool pcmonly=false);

    /// Destructor: Finalizes & closes the WAV file.
    ~WavOutFile();

    /// Write data to WAV file. This function works only with 8bit samples.
    /// Throws a 'runtime_error' exception if writing to file fails.
    void write(const unsigned char *buffer, ///< Pointer to sample data buffer.
               int numElems                 ///< How many array items are to be written to file.
              );

    /// Write data to WAV file. Throws a 'runtime_error' exception if writing to
    /// file fails.
    void write(const short *buffer,     ///< Pointer to sample data buffer.
               int numElems             ///< How many array items are to be written to file.
              );

    /// Write data to WAV file in floating point format, saturating sample values to range
    /// [-1..+1[. Throws a 'runtime_error' exception if writing to file fails.
    void write(const float *buffer,     ///< Pointer to sample data buffer.
               int numElems             ///< How many array items are to be written to file.
              );
    void write(const double *buffer,     ///< Pointer to sample data buffer.
               int numElems             ///< How many array items are to be written to file.
    );
};

#endif
