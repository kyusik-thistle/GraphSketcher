//
//  PreviewProvider.h
//  GraphSketcherPreview
//
//  Created by Kyusik Chung on 6/25/26.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

// Data-based preview provider (returns the document's embedded preview.pdf). Not a view-controller
// based preview, so it does not adopt QLPreviewingController.
@interface PreviewProvider : QLPreviewProvider

@end
