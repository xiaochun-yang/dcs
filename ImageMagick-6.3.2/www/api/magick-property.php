<p class="navigation-index">[ <a href="#MagickGetAntialias">MagickGetAntialias</a> | <a href="#MagickGetCompression">MagickGetCompression</a> | <a href="#MagickGetCompressionQuality">MagickGetCompressionQuality</a> | <a href="#MagickGetCopyright">MagickGetCopyright</a> | <a href="#MagickGetException">MagickGetException</a> | <a href="#MagickGetFilename">MagickGetFilename</a> | <a href="#MagickGetFormat">MagickGetFormat</a> | <a href="#MagickGetHomeURL">MagickGetHomeURL</a> | <a href="#MagickGetInterlaceScheme">MagickGetInterlaceScheme</a> | <a href="#MagickGetInterpolateMethod">MagickGetInterpolateMethod</a> | <a href="#MagickGetOption">MagickGetOption</a> | <a href="#MagickGetPackageName">MagickGetPackageName</a> | <a href="#MagickGetPage">MagickGetPage</a> | <a href="#MagickGetQuantumDepth">MagickGetQuantumDepth</a> | <a href="#MagickGetQuantumRange">MagickGetQuantumRange</a> | <a href="#MagickGetReleaseDate">MagickGetReleaseDate</a> | <a href="#MagickGetResource">MagickGetResource</a> | <a href="#MagickGetResourceLimit">MagickGetResourceLimit</a> | <a href="#MagickGetSamplingFactors">MagickGetSamplingFactors</a> | <a href="#MagickGetSize">MagickGetSize</a> | <a href="#MagickGetSizeOffset">MagickGetSizeOffset</a> | <a href="#MagickGetVersion">MagickGetVersion</a> | <a href="#MagickSetAntialias">MagickSetAntialias</a> | <a href="#MagickSetBackgroundColor">MagickSetBackgroundColor</a> | <a href="#MagickSetCompression">MagickSetCompression</a> | <a href="#MagickSetCompressionQuality">MagickSetCompressionQuality</a> | <a href="#MagickSetFilename">MagickSetFilename</a> | <a href="#MagickSetFormat">MagickSetFormat</a> | <a href="#MagickSetInterlaceScheme">MagickSetInterlaceScheme</a> | <a href="#MagickSetInterpolateMethod">MagickSetInterpolateMethod</a> | <a href="#MagickSetOption">MagickSetOption</a> | <a href="#MagickSetPage">MagickSetPage</a> | <a href="#MagickSetPassphrase">MagickSetPassphrase</a> | <a href="#MagickSetProgressMonitor">MagickSetProgressMonitor</a> | <a href="#MagickSetResourceLimit">MagickSetResourceLimit</a> | <a href="#MagickSetResolution">MagickSetResolution</a> | <a href="#MagickSetSamplingFactors">MagickSetSamplingFactors</a> | <a href="#MagickSetSize">MagickSetSize</a> | <a href="#MagickSetSizeOffset">MagickSetSizeOffset</a> | <a href="#MagickSetType">MagickSetType</a> ]</p>

<div style="margin: auto;">
  <h2><a name="MagickGetAntialias">MagickGetAntialias</a></h2>
</div>

<p>MagickGetAntialias() returns the antialias property associated with the wand.</p></ol>

<p>The format of the MagickGetAntialias method is:</p>

<pre class="code">
  MagickBooleanType MagickGetAntialias(const MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand. </p>
<div style="margin: auto;">
  <h2><a name="MagickGetCompression">MagickGetCompression</a></h2>
</div>

<p>MagickGetCompression() gets the wand compression.</p></ol>

<p>The format of the MagickGetCompression method is:</p>

<pre class="code">
  CompressionType MagickGetCompression(MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetCompressionQuality">MagickGetCompressionQuality</a></h2>
</div>

<p>MagickGetCompressionQuality() gets the wand compression quality.</p></ol>

<p>The format of the MagickGetCompressionQuality method is:</p>

<pre class="code">
  unsigned long MagickGetCompressionQuality(MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetCopyright">MagickGetCopyright</a></h2>
</div>

<p>MagickGetCopyright() returns the ImageMagick API copyright as a string constant.</p></ol>

<p>The format of the MagickGetCopyright method is:</p>

<pre class="code">
  const char *MagickGetCopyright(void)
</pre>

<div style="margin: auto;">
  <h2><a name="MagickGetException">MagickGetException</a></h2>
</div>

<p>MagickGetException() returns the severity, reason, and description of any error that occurs when using other methods in this API.</p></ol>

<p>The format of the MagickGetException method is:</p>

<pre class="code">
  char *MagickGetException(MagickWand *wand,ExceptionType *severity)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>severity</h5>
<ol><p>The severity of the error is returned here.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetFilename">MagickGetFilename</a></h2>
</div>

<p>MagickGetFilename() returns the filename associated with an image sequence.</p></ol>

<p>The format of the MagickGetFilename method is:</p>

<pre class="code">
  const char *MagickGetFilename(const MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>


<div style="margin: auto;">
  <h2><a name="MagickGetFormat">MagickGetFormat</a></h2>
</div>

<p>MagickGetFormat() returns the format of the magick wand.</p></ol>

<p>The format of the MagickGetFormat method is:</p>

<pre class="code">
  const char MagickGetFormat(MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetHomeURL">MagickGetHomeURL</a></h2>
</div>

<p>MagickGetHomeURL() returns the ImageMagick home URL.</p></ol>

<p>The format of the MagickGetHomeURL method is:</p>

<pre class="code">
  char *MagickGetHomeURL(void)
</pre>

<div style="margin: auto;">
  <h2><a name="MagickGetInterlaceScheme">MagickGetInterlaceScheme</a></h2>
</div>

<p>MagickGetInterlaceScheme() gets the wand interlace scheme.</p></ol>

<p>The format of the MagickGetInterlaceScheme method is:</p>

<pre class="code">
  InterlaceType MagickGetInterlaceScheme(MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetInterpolateMethod">MagickGetInterpolateMethod</a></h2>
</div>

<p>MagickGetInterpolateMethod() gets the wand compression.</p></ol>

<p>The format of the MagickGetInterpolateMethod method is:</p>

<pre class="code">
  InterpolatePixelMethod MagickGetInterpolateMethod(MagickWand *wand)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetOption">MagickGetOption</a></h2>
</div>

<p>MagickGetOption() returns a value associated with a wand and the specified key.  Use MagickRelinquishMemory() to free the value when you are finished with it.</p></ol>

<p>The format of the MagickGetOption method is:</p>

<pre class="code">
  char *MagickGetOption(MagickWand *wand,const char *key)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>key</h5>
<ol><p>The key.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetPackageName">MagickGetPackageName</a></h2>
</div>

<p>MagickGetPackageName() returns the ImageMagick package name as a string constant.</p></ol>

<p>The format of the MagickGetPackageName method is:</p>

<pre class="code">
  const char *MagickGetPackageName(void)
</pre>


<div style="margin: auto;">
  <h2><a name="MagickGetPage">MagickGetPage</a></h2>
</div>

<p>MagickGetPage() returns the page geometry associated with the magick wand.</p></ol>

<p>The format of the MagickGetPage method is:</p>

<pre class="code">
  MagickBooleanType MagickGetPage(const MagickWand *wand,
    unsigned long *width,unsigned long *height,long *x,long *y)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>width</h5>
<ol><p>The page width.</p></ol>

<h5>height</h5>
<ol><p>page height.</p></ol>

<h5>x</h5>
<ol><p>The page x-offset.</p></ol>

<h5>y</h5>
<ol><p>The page y-offset.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetQuantumDepth">MagickGetQuantumDepth</a></h2>
</div>

<p>MagickGetQuantumDepth() returns the ImageMagick quantum depth as a string constant.</p></ol>

<p>The format of the MagickGetQuantumDepth method is:</p>

<pre class="code">
  const char *MagickGetQuantumDepth(unsigned long *depth)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>depth</h5>
<ol><p>The quantum depth is returned as a number.</p></ol>


<div style="margin: auto;">
  <h2><a name="MagickGetQuantumRange">MagickGetQuantumRange</a></h2>
</div>

<p>MagickGetQuantumRange() returns the ImageMagick quantum range as a string constant.</p></ol>

<p>The format of the MagickGetQuantumRange method is:</p>

<pre class="code">
  const char *MagickGetQuantumRange(unsigned long *range)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>range</h5>
<ol><p>The quantum range is returned as a number.</p></ol>


<div style="margin: auto;">
  <h2><a name="MagickGetReleaseDate">MagickGetReleaseDate</a></h2>
</div>

<p>MagickGetReleaseDate() returns the ImageMagick release date as a string constant.</p></ol>

<p>The format of the MagickGetReleaseDate method is:</p>

<pre class="code">
  const char *MagickGetReleaseDate(void)
</pre>

<div style="margin: auto;">
  <h2><a name="MagickGetResource">MagickGetResource</a></h2>
</div>

<p>MagickGetResource() returns the specified resource in megabytes.</p></ol>

<p>The format of the MagickGetResource method is:</p>

<pre class="code">
  unsigned long MagickGetResource(const ResourceType type)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetResourceLimit">MagickGetResourceLimit</a></h2>
</div>

<p>MagickGetResourceLimit() returns the specified resource limit in megabytes.</p></ol>

<p>The format of the MagickGetResourceLimit method is:</p>

<pre class="code">
  unsigned long MagickGetResourceLimit(const ResourceType type)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetSamplingFactors">MagickGetSamplingFactors</a></h2>
</div>

<p>MagickGetSamplingFactors() gets the horizontal and vertical sampling factor.</p></ol>

<p>The format of the MagickGetSamplingFactors method is:</p>

<pre class="code">
  double *MagickGetSamplingFactor(MagickWand *wand,
    unsigned long *number_factors)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>number_factors</h5>
<ol><p>The number of factors in the returned array.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetSize">MagickGetSize</a></h2>
</div>

<p>MagickGetSize() returns the size associated with the magick wand.</p></ol>

<p>The format of the MagickGetSize method is:</p>

<pre class="code">
  MagickBooleanType MagickGetSize(const MagickWand *wand,
    unsigned long *columns,unsigned long *rows)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>columns</h5>
<ol><p>The width in pixels.</p></ol>

<h5>height</h5>
<ol><p>The height in pixels.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetSizeOffset">MagickGetSizeOffset</a></h2>
</div>

<p>MagickGetSizeOffset() returns the size offset associated with the magick wand.</p></ol>

<p>The format of the MagickGetSizeOffset method is:</p>

<pre class="code">
  MagickBooleanType MagickGetSizeOffset(const MagickWand *wand,
    long *offset)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>offset</h5>
<ol><p>The image offset.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickGetVersion">MagickGetVersion</a></h2>
</div>

<p>MagickGetVersion() returns the ImageMagick API version as a string constant and as a number.</p></ol>

<p>The format of the MagickGetVersion method is:</p>

<pre class="code">
  const char *MagickGetVersion(unsigned long *version)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>version</h5>
<ol><p>The ImageMagick version is returned as a number.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetAntialias">MagickSetAntialias</a></h2>
</div>

<p>MagickSetAntialias() sets the antialias propery of the wand.</p></ol>

<p>The format of the MagickSetAntialias method is:</p>

<pre class="code">
  MagickBooleanType MagickSetAntialias(MagickWand *wand,
    const MagickBooleanType antialias)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>antialias</h5>
<ol><p>The antialias property.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetBackgroundColor">MagickSetBackgroundColor</a></h2>
</div>

<p>MagickSetBackgroundColor() sets the wand background color.</p></ol>

<p>The format of the MagickSetBackgroundColor method is:</p>

<pre class="code">
  MagickBooleanType MagickSetBackgroundColor(MagickWand *wand,
    const PixelWand *background)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>background</h5>
<ol><p>The background pixel wand.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetCompression">MagickSetCompression</a></h2>
</div>

<p>MagickSetCompression() sets the wand compression type.</p></ol>

<p>The format of the MagickSetCompression method is:</p>

<pre class="code">
  MagickBooleanType MagickSetCompression(MagickWand *wand,
    const CompressionType compression)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>compression</h5>
<ol><p>The wand compression.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetCompressionQuality">MagickSetCompressionQuality</a></h2>
</div>

<p>MagickSetCompressionQuality() sets the wand compression quality.</p></ol>

<p>The format of the MagickSetCompressionQuality method is:</p>

<pre class="code">
  MagickBooleanType MagickSetCompressionQuality(MagickWand *wand,
    const unsigned long quality)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>quality</h5>
<ol><p>The wand compression quality.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetFilename">MagickSetFilename</a></h2>
</div>

<p>MagickSetFilename() sets the filename before you read or write an image file.</p></ol>

<p>The format of the MagickSetFilename method is:</p>

<pre class="code">
  MagickBooleanType MagickSetFilename(MagickWand *wand,
    const char *filename)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>filename</h5>
<ol><p>The image filename.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetFormat">MagickSetFormat</a></h2>
</div>

<p>MagickSetFormat() sets the format of the magick wand.</p></ol>

<p>The format of the MagickSetFormat method is:</p>

<pre class="code">
  MagickBooleanType MagickSetFormat(MagickWand *wand,const char *format)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>format</h5>
<ol><p>The image format.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetInterlaceScheme">MagickSetInterlaceScheme</a></h2>
</div>

<p>MagickSetInterlaceScheme() sets the image compression.</p></ol>

<p>The format of the MagickSetInterlaceScheme method is:</p>

<pre class="code">
  MagickBooleanType MagickSetInterlaceScheme(MagickWand *wand,
    const InterlaceType interlace_scheme)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>interlace_scheme</h5>
<ol><p>The image interlace scheme: NoInterlace, LineInterlace, PlaneInterlace, PartitionInterlace.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetInterpolateMethod">MagickSetInterpolateMethod</a></h2>
</div>

<p>MagickSetInterpolateMethod() sets the interpolate pixel method.</p></ol>

<p>The format of the MagickSetInterpolateMethod method is:</p>

<pre class="code">
  MagickBooleanType MagickSetInterpolateMethod(MagickWand *wand,
    const InterpolateMethodPixel method)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>method</h5>
<ol><p>The interpolate pixel method.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetOption">MagickSetOption</a></h2>
</div>

<p>MagickSetOption() associates one or options with the wand (.e.g MagickSetOption(wand,"jpeg:perserve","yes")).</p></ol>

<p>The format of the MagickSetOption method is:</p>

<pre class="code">
  MagickBooleanType MagickSetOption(MagickWand *wand,const char *key,
    const char *value)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>key</h5>
<ol><p>The key.</p></ol>

<h5>value</h5>
<ol><p>The value.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetPage">MagickSetPage</a></h2>
</div>

<p>MagickSetPage() sets the page geometry of the magick wand.</p></ol>

<p>The format of the MagickSetPage method is:</p>

<pre class="code">
  MagickBooleanType MagickSetPage(MagickWand *wand,
    const unsigned long width,const unsigned long height,const long x,
    const long y)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>width</h5>
<ol><p>The page width.</p></ol>

<h5>height</h5>
<ol><p>The page height.</p></ol>

<h5>x</h5>
<ol><p>The page x-offset.</p></ol>

<h5>y</h5>
<ol><p>The page y-offset.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetPassphrase">MagickSetPassphrase</a></h2>
</div>

<p>MagickSetPassphrase() sets the passphrase.</p></ol>

<p>The format of the MagickSetPassphrase method is:</p>

<pre class="code">
  MagickBooleanType MagickSetPassphrase(MagickWand *wand,
    const char *passphrase)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>passphrase</h5>
<ol><p>The passphrase.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetProgressMonitor">MagickSetProgressMonitor</a></h2>
</div>

<p>MagickSetProgressMonitor() sets the wand progress monitor to the specified method and returns the previous progress monitor if any.  The progress monitor method looks like this:</p>

<pre class="text">
      MagickBooleanType MagickProgressMonitor(const char *text,
  const MagickOffsetType offset,const MagickSizeType span,
  void *client_data)
</pre>

<p>If the progress monitor returns MagickFalse, the current operation is interrupted.</p></ol>

<p>The format of the MagickSetProgressMonitor method is:</p>

<pre class="code">
  MagickProgressMonitor MagickSetProgressMonitor(MagickWand *wand
    const MagickProgressMonitor progress_monitor,void *client_data)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>progress_monitor</h5>
<ol><p>Specifies a pointer to a method to monitor progress of an image operation.</p></ol>

<h5>client_data</h5>
<ol><p>Specifies a pointer to any client data.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetResourceLimit">MagickSetResourceLimit</a></h2>
</div>

<p>MagickSetResourceLimit() sets the limit for a particular resource in megabytes.</p></ol>

<p>The format of the MagickSetResourceLimit method is:</p>

<pre class="code">
  MagickBooleanType MagickSetResourceLimit(const ResourceType type,
    const unsigned long *limit)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>type</h5>
<ol><p>The type of resource: AreaResource, MemoryResource, MapResource, DiskResource, FileResource.</p></ol>

<p>o The maximum limit for the resource.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetResolution">MagickSetResolution</a></h2>
</div>

<p>MagickSetResolution() sets the image resolution.</p></ol>

<p>The format of the MagickSetResolution method is:</p>

<pre class="code">
  MagickBooleanType MagickSetResolution(MagickWand *wand,
    const double x_resolution,const doubtl y_resolution)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>x_resolution</h5>
<ol><p>The image x resolution.</p></ol>

<h5>y_resolution</h5>
<ol><p>The image y resolution.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetSamplingFactors">MagickSetSamplingFactors</a></h2>
</div>

<p>MagickSetSamplingFactors() sets the image sampling factors.</p></ol>

<p>The format of the MagickSetSamplingFactors method is:</p>

<pre class="code">
  MagickBooleanType MagickSetSamplingFactors(MagickWand *wand,
    const unsigned long number_factors,const double *sampling_factors)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>number_factoes</h5>
<ol><p>The number of factors.</p></ol>

<h5>sampling_factors</h5>
<ol><p>An array of doubles representing the sampling factor for each color component (in RGB order).</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetSize">MagickSetSize</a></h2>
</div>

<p>MagickSetSize() sets the size of the magick wand.  Set it before you read a raw image format such as RGB, GRAY, or CMYK.</p></ol>

<p>The format of the MagickSetSize method is:</p>

<pre class="code">
  MagickBooleanType MagickSetSize(MagickWand *wand,
    const unsigned long columns,const unsigned long rows)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>columns</h5>
<ol><p>The width in pixels.</p></ol>

<h5>rows</h5>
<ol><p>The rows in pixels.</p></ol>


<div style="margin: auto;">
  <h2><a name="MagickSetSizeOffset">MagickSetSizeOffset</a></h2>
</div>

<p>MagickSetSizeOffset() sets the size and offset of the magick wand.  Set it before you read a raw image format such as RGB, GRAY, or CMYK.</p></ol>

<p>The format of the MagickSetSizeOffset method is:</p>

<pre class="code">
  MagickBooleanType MagickSetSizeOffset(MagickWand *wand,
    const unsigned long columns,const unsigned long rows,
    const long offset)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>columns</h5>
<ol><p>The width in pixels.</p></ol>

<h5>rows</h5>
<ol><p>The rows in pixels.</p></ol>

<div style="margin: auto;">
  <h2><a name="MagickSetType">MagickSetType</a></h2>
</div>

<p>MagickSetType() sets the image type attribute.</p></ol>

<p>The format of the MagickSetType method is:</p>

<pre class="code">
  MagickBooleanType MagickSetType(MagickWand *wand,
    const ImageType image_type)
</pre>

<p>A description of each parameter follows:</p></ol>

<h5>wand</h5>
<ol><p>The magick wand.</p></ol>

<h5>image_type</h5>
<ol><p>The image type:   UndefinedType, BilevelType, GrayscaleType, GrayscaleMatteType, PaletteType, PaletteMatteType, TrueColorType, TrueColorMatteType, ColorSeparationType, ColorSeparationMatteType, or OptimizeType.</p></ol>
