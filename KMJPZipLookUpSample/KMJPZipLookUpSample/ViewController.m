//
//  ViewController.m
//  KMJPZipLookUpSample
//
//  Created by Kosuke Matsuda on 2013/04/23.
//  Copyright (c) 2013年 matsuda. All rights reserved.
//

#import "ViewController.h"
#import "KMJPZipLookUpClient.h"
#import "KMJPZipLookUpResponse.h"
#import "KMJPZipLookUpAddressListViewController.h"

@interface ViewController () <UIPopoverControllerDelegate> {
    UIPopoverController *_popover;
    // ZipSearch
    KMJPZipLookUpResponse *_response;
}

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)lookUp:(id)sender
{
    [self.view endEditing:YES];
    [self requestAPIWithZipcode:self.textField.text];
}

- (void)requestAPIWithZipcode:(NSString *)zipcode
{
    NSError *error = nil;
    if (![[KMJPZipLookUpClient sharedClient] validateZipcode:zipcode withError:&error]) {
        NSDictionary *userInfo = error.userInfo;
        NSString *message = userInfo[NSLocalizedDescriptionKey];
        [self showAlertNotFoundAddressListWithMessage:message];
        return;
    }

    [self showIndicator];

    __weak typeof(self) wself = self;
    [[KMJPZipLookUpClient sharedClient] lookUpWithZipcode:zipcode success:^(AFHTTPRequestOperation *operation, KMJPZipLookUpResponse *response){
//        NSLog(@"success >>>>>>>> %@", response);
        _response = response;
        [wself didFinishCheckZipSearchAPI];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
//        NSLog(@"failure >>>>>>>> %@", error);
        [wself didFailCheckZipSearchAPIWithError:error];
    }];
}

- (void)didFinishCheckZipSearchAPI
{
    [self hideIndicator];

    NSArray *addresses = _response.addresses;
    if ([addresses count] > 0) {
        [self presentAddressListViewController];
    } else {
        [self showAlertNotFoundAddressListWithMessage:@"該当する住所が見つかりませんでした。"];
    }
}

- (void)didFailCheckZipSearchAPIWithError:(NSError *)error
{
    [self hideIndicator];

    NSString *message = [error localizedDescription];
    [self showAlertNotFoundAddressListWithMessage:message];
}

#pragma mark - Private

- (void)didSelectAddress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    KMJPZipLookUpAddress *address = [userInfo objectForKey:kKMJPZipLookUpAddressListResultsKey];
    self.label.text = [address fullAddress];

    [self dismissAddressListViewController];
}

- (void)showAlertNotFoundAddressListWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"郵便番号検索" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (KMJPZipLookUpAddressListViewController *)addressListViewController
{
    KMJPZipLookUpAddressListViewController *controller = [[KMJPZipLookUpAddressListViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.response = _response;
    return controller;
}

- (void)presentAddressListViewController
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAddress:) name:kKMJPZipLookUpAddressListDidSelectNotification object:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self presentAddressListPopover];
    } else {
        [self presentAddressListModalController];
    }
}

- (void)dismissAddressListViewController
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKMJPZipLookUpAddressListDidSelectNotification object:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [self addressListPopover];
        [popover dismissPopoverAnimated:YES];
        _popover = nil;
    } else {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)presentAddressListModalController
{
    KMJPZipLookUpAddressListViewController *controller = [self addressListViewController];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)presentAddressListPopover
{
    UIPopoverController *popover = [self addressListPopover];
    [popover setPopoverContentSize:CGSizeMake(400.f, 132.f)];
    [popover presentPopoverFromRect:self.textField.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

- (UIPopoverController *)addressListPopover
{
    if (_popover) {
        return _popover;
    }

    KMJPZipLookUpAddressListViewController *popoverContent = [self addressListViewController];
    popoverContent.modalInPopover = YES;
    _popover = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
    _popover.delegate = self;
    return _popover;
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController isEqual:_popover]) {
        _popover = nil;
    }
}

- (void)showIndicator
{
    UIView *grayer = [[UIView alloc] initWithFrame:self.view.bounds];
    grayer.backgroundColor = [UIColor blackColor];
    grayer.alpha = 0.5;
    grayer.autoresizesSubviews = YES;
    grayer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:grayer];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin );
    indicator.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    [indicator startAnimating];
    [self.view addSubview:indicator];
}

- (void)hideIndicator
{
    if ([self.view.subviews count] >= 2) {
        NSEnumerator *enumerator = [self.view.subviews reverseObjectEnumerator];
        BOOL isExist = NO;
        for (UIView *v in enumerator) {
            if (isExist) {
                [v removeFromSuperview];
                break;
            }
            if ([v isKindOfClass:[UIActivityIndicatorView class]]) {
                UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)v;
                [indicator stopAnimating];
                [indicator removeFromSuperview];
                isExist = YES;
            }
        }
    }
}

@end
