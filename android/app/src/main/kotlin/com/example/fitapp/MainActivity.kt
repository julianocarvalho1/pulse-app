package com.example.fitapp

import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterFragmentActivity() {
    private val pdfChannel = "pulse/pdf_text"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PDFBoxResourceLoader.init(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pdfChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "extractText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("PDF_PATH", "Caminho do PDF não informado.", null)
                    return@setMethodCallHandler
                }

                thread(name = "pulse-pdf-text") {
                    try {
                        val file = File(path)
                        if (!file.exists()) {
                            runOnUiThread {
                                result.error("PDF_NOT_FOUND", "Arquivo PDF não encontrado.", null)
                            }
                            return@thread
                        }

                        val text = PDDocument.load(file).use { document ->
                            PDFTextStripper().getText(document)
                        }
                        runOnUiThread { result.success(text) }
                    } catch (error: Throwable) {
                        runOnUiThread {
                            result.error(
                                "PDF_READ_ERROR",
                                "Não foi possível extrair o texto deste PDF.",
                                error.message,
                            )
                        }
                    }
                }
            }
    }
}
