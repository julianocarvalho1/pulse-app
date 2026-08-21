# PdfBox-Android references the optional JP2Android decoder for JPX/JPEG 2000
# images. PULSE does not bundle that optional library; PDF text extraction keeps
# working and unsupported JPX images are ignored by PdfBox-Android.
-dontwarn com.gemalto.jp2.JP2Decoder
