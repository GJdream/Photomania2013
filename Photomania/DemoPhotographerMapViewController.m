//
//  DemoPhotographerMapViewController.m
//  Photomania
//
//  Created by Martin Mandl on 20.07.13.
//  Copyright (c) 2013 m2m server software gmbh. All rights reserved.
//

#import "DemoPhotographerMapViewController.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"

@interface DemoPhotographerMapViewController ()

@end

@implementation DemoPhotographerMapViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.managedObjectContext) {
        [self useDocument];
    }
}

- (void)useDocument
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                         inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"Demo Document"];
    
    UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document saveToURL:url
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              self.managedObjectContext = document.managedObjectContext;
              [self refresh];
          }];
    } else if (document.documentState == UIDocumentStateClosed) {
        [document openWithCompletionHandler:^(BOOL success) {
            self.managedObjectContext = document.managedObjectContext;
            [self refresh];
        }];
    } else {
        self.managedObjectContext = document.managedObjectContext;
    }
}

- (IBAction)refresh
{
    dispatch_queue_t fetchQ = dispatch_queue_create("Flickr Fetch", NULL);
    dispatch_async(fetchQ, ^{
        NSArray *photos = [FlickrFetcher latestGeoreferencedPhotos];
        // put the photos in Core Data
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *photo in photos) {
                [Photo photoWithFlickrInfo:photo
                    inManagedObjectContext:self.managedObjectContext];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reload];
            });
        }];
    });
}

@end