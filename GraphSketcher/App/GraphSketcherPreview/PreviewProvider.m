//
//  PreviewProvider.m
//  GraphSketcherPreview
//
//  Data-based Quick Look preview for GraphSketcher (.ograph) documents: returns the vector chart
//  preview (preview.pdf) embedded in each document. See OGraphPreviewExtraction.h.
//

#import "PreviewProvider.h"
#import <CoreGraphics/CoreGraphics.h>
#import <PDFKit/PDFKit.h>
#import "../OGraphPreviewExtraction.h"

@implementation PreviewProvider

- (void)providePreviewForFileRequest:(QLFilePreviewRequest *)request completionHandler:(void (^)(QLPreviewReply * _Nullable reply, NSError * _Nullable error))handler
{
    NSData *pdfData = OGraphCopyPreviewPDF(request.fileURL);
    if (pdfData == nil) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                         userInfo:@{NSLocalizedDescriptionKey: @"This GraphSketcher document has no embedded preview."}];
        handler(nil, error);
        return;
    }

    // Size the preview to the PDF's page box (falling back to a sane default).
    CGSize contentSize = CGSizeMake(800, 600);
    {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)pdfData);
        CGPDFDocumentRef document = provider ? CGPDFDocumentCreateWithProvider(provider) : NULL;
        CGPDFPageRef page = document ? CGPDFDocumentGetPage(document, 1) : NULL;
        if (page != NULL) {
            CGRect box = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
            if (CGRectIsEmpty(box)) box = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            if (!CGRectIsEmpty(box)) contentSize = box.size;
        }
        if (document) CGPDFDocumentRelease(document);
        if (provider) CGDataProviderRelease(provider);
    }

    // Hand Quick Look a real PDFDocument so it uses the system's native PDF previewer -- a large,
    // zoomable window, like previewing a PDF/JPEG. (A data-based preview is shown at a small fixed
    // size regardless of the content size we report, which is why the window was tiny before.)
    QLPreviewReply *reply = [[QLPreviewReply alloc] initForPDFWithPageSize:contentSize
                                                    documentCreationBlock:^PDFDocument * _Nullable(QLPreviewReply * _Nonnull replyToUpdate, NSError *__autoreleasing _Nullable * _Nullable error) {
        PDFDocument *document = [[PDFDocument alloc] initWithData:pdfData];
        if (document == nil && error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError
                                     userInfo:@{NSLocalizedDescriptionKey: @"Could not read the embedded chart preview."}];
        }
        return document;
    }];
    handler(reply, nil);
}

@end
