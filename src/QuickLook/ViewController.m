//
//  ViewController.m
//  QuickLook
//
//  Created by Paul Jackson on 24/02/2017.
//  Copyright © 2017 Paul Jackson. All rights reserved.
//

#import "ViewController.h"
#import <TargetConditionals.h>

@import QuickLook;

/*
 *  Quicklook Preview Item
 */
@interface PreviewItem : NSObject <QLPreviewItem>
@property(readonly, nullable, nonatomic) NSURL      * previewItemURL;
@property(readonly, nullable, nonatomic) NSString   * previewItemTitle;
@end
@implementation PreviewItem
- (instancetype)initPreviewURL:(NSURL *)docURL WithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _previewItemURL = [docURL copy];
        _previewItemTitle = [title copy];

        /*
         Unfortunately there's a bug in iOS 11.2 that prevents bundled PDF's from displaying when using
         the QLPreviewController. This appears to only be a problem when attempting to load the PDF on a
         physical device; everything works as expected when running in the simulator.
         */

#if !TARGET_OS_SIMULATOR
        if (@available(iOS 11.2, *)) {
            [self copydoc];
        }
#endif
    }
    return self;
}

/*
 *  helper to copy resource to a location that the QLPreviewController can see.
 */
-(void)copydoc {
    NSFileManager *fm = [NSFileManager defaultManager];

    /*
     *  folder bookkeeping
     */

    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    if (![fm fileExistsAtPath:folderPath]) {
        [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    /*
     *  migrate the target file to a location visible to the QLPreviewController
     */

    NSString *filePath = [folderPath stringByAppendingPathComponent:[_previewItemURL.absoluteString lastPathComponent]];
    if (![fm fileExistsAtPath:filePath]) {
        [fm copyItemAtPath:_previewItemURL.relativePath toPath:filePath error:nil];
    }

    /*
     *  persist the cached location
     */

    _previewItemURL = [NSURL fileURLWithPath:filePath];
}
@end

/*
 *  QuickLook Datasource for rending PDF docs
 */
@interface PDFDataSource : NSObject <QLPreviewControllerDataSource>
@property (strong, nonatomic) PreviewItem *item;
@end
@implementation PDFDataSource
- (instancetype)initWithPreviewItem:(PreviewItem *)item {
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}
- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.item;
}
@end

@interface ViewController ()
@property (strong, nonatomic) PDFDataSource *pdfDatasource;
@end

@implementation ViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    /*
     *  get the path to the pdf resource.
     */

  //  NSString *path = [[NSBundle mainBundle] pathForResource:@"article" ofType:@"pdf"];
   // NSURL *docURL = [NSURL fileURLWithPath:path];
  __block  NSURL *docURL;
    NSURL *url = [NSURL URLWithString:@"https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"];
    NSString * pdfPathComponent = [url lastPathComponent];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      dispatch_sync(dispatch_get_main_queue(), ^{
                                          if(data){
                                              NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                              NSString *documentDirectory=[paths objectAtIndex:0];
                                              
                                              NSString *finalPath=[documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"%@", pdfPathComponent]]; //check your path correctly and provide your name dynamically
                                              NSLog(@"finalpath--%@",finalPath);
                                              
                                              [data writeToFile:finalPath atomically:YES];
                                              docURL = [NSURL fileURLWithPath:finalPath];
                                              QLPreviewController *qlController = [[QLPreviewController alloc] init];
                                              
                                              PreviewItem *item = [[PreviewItem alloc] initPreviewURL:docURL WithTitle:@"Article"];
                                              self.pdfDatasource = [[PDFDataSource alloc] initWithPreviewItem:item];
                                              qlController.dataSource = self.pdfDatasource;
                                              [self addChildViewController:qlController];
                                              CGFloat width = self.view.frame.size.width;
                                              CGFloat height = self.view.frame.size.height;
                                              qlController.view.frame = CGRectMake(0, 0, width, height);
                                              [self.view addSubview:qlController.view];
                                              [qlController didMoveToParentViewController:self];
                                          }
                                      });
                                  }];
 [task resume];

    /*
     *  create the Quicklook controller.
     */

/*    QLPreviewController *qlController = [[QLPreviewController alloc] init];

    PreviewItem *item = [[PreviewItem alloc] initPreviewURL:docURL WithTitle:@"Article"];
    self.pdfDatasource = [[PDFDataSource alloc] initWithPreviewItem:item];
    qlController.dataSource = self.pdfDatasource;
    [self addChildViewController:qlController];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    qlController.view.frame = CGRectMake(0, 0, width, height);
    [self.view addSubview:qlController.view];
    [qlController didMoveToParentViewController:self];*/

    /*
     *  present the document.
     */
 //   [self.view addSubview:qlController.view];
   // [self presentViewController:qlController animated:YES completion:nil];
}
@end
