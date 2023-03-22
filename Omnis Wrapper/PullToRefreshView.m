/*  Changes:
 Date       Edit        Fault       Description
 
 */

#import "PullToRefreshView.h"
//#import "AppDelegate.h"

#define TEXT_COLOR	 [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


@interface PullToRefreshView (Private)

@property (nonatomic, assign) PullToRefreshViewState state;

@end

@implementation PullToRefreshView
@synthesize delegate;
@synthesize scrollView;

- (void)showActivity:(BOOL)shouldShow animated:(BOOL)animated {
    if (shouldShow) [activityView startAnimating];
    else [activityView stopAnimating];
    
    [UIView animateWithDuration:(animated ? 0.1f : 0.0) animations:^{
			self->arrowImage.opacity = (shouldShow ? 0.0 : 1.0);
    }];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView animateWithDuration:0.1f animations:^{
			self->arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    }];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0.0f, 0.0f - scroll.bounds.size.height, scroll.bounds.size.width, scroll.bounds.size.height);
    
    if ((self = [super initWithFrame:frame])) {
        scrollView = scroll;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
        
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor colorWithRed:1 green:1.0 blue:1.0 alpha:1.0];
			
		statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f, self.frame.size.width, 20.0f)];
		statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		statusLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		statusLabel.textColor = TEXT_COLOR;
		statusLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		statusLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:statusLabel];
        
		arrowImage = [[CALayer alloc] init];
		arrowImage.frame = CGRectMake(10.0f, frame.size.height - 60.0f, 24.0f, 52.0f);
		arrowImage.contentsGravity = kCAGravityResizeAspect;
		arrowImage.contents = (id) [UIImage imageNamed:@"arrow"].CGImage;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			arrowImage.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
        
		[self.layer addSublayer:arrowImage];
        
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityView.frame = CGRectMake(10.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
		[self addSubview:activityView];
        
		[self setState:PullToRefreshViewStateNormal];
    }
    
    return self;
}

#pragma mark -
#pragma mark Setters

- (void)refreshLastUpdatedDate {
    NSDate *date = [NSDate date];
    
	if ([delegate respondsToSelector:@selector(pullToRefreshViewLastUpdated:)])
		date = [delegate pullToRefreshViewLastUpdated:self];
}

- (void)setState:(PullToRefreshViewState)state_ {
    state = state_;
    
	switch (state) {
		case PullToRefreshViewStateReady:
			statusLabel.text = NSLocalizedString(@"Release For Menu", nil);
			[self showActivity:NO animated:NO];
            [self setImageFlipped:YES];
            scrollView.contentInset = UIEdgeInsetsZero;
			break;
            
		case PullToRefreshViewStateNormal:
			statusLabel.text = NSLocalizedString(@"Pull Down For Menu", nil);
			[self showActivity:NO animated:NO];
            [self setImageFlipped:NO];
			[self refreshLastUpdatedDate];
            scrollView.contentInset = UIEdgeInsetsZero;
			break;
            
		case PullToRefreshViewStateLoading:
			[self showActivity:YES animated:YES];
            [self setImageFlipped:NO];
			break;
            
		default:
			break;
	}
}

#pragma mark -
#pragma mark UIScrollView

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSInteger pullHeight = -120;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if( UIDeviceOrientationLandscapeLeft == orientation || UIDeviceOrientationLandscapeRight == orientation )
        pullHeight = -70;
    
    if ([keyPath isEqualToString:@"contentOffset"])
    {
        if (scrollView.isDragging)
        {
            if (state == PullToRefreshViewStateReady)
            {
                if (scrollView.contentOffset.y > pullHeight && scrollView.contentOffset.y < -20.0f)
                    [self setState:PullToRefreshViewStateNormal];
            } else if (state == PullToRefreshViewStateNormal)
            {
                if (scrollView.contentOffset.y < pullHeight)
                    [self setState:PullToRefreshViewStateReady];
            } else if (state == PullToRefreshViewStateLoading)
            {
                if (scrollView.contentOffset.y >= -20)
                    scrollView.contentInset = UIEdgeInsetsZero;
                else
                    scrollView.contentInset = UIEdgeInsetsMake(MIN(-scrollView.contentOffset.y, 165.0f), 0, 0, 0);
            }
        } else
        {
            if (state == PullToRefreshViewStateReady)
            {
                [UIView animateWithDuration:0.2f animations:^
                {
                    [self setState:PullToRefreshViewStateLoading];
                }];
                
                if ([delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)])
                    [delegate pullToRefreshViewShouldRefresh:self];
            }
        }
        self.frame = CGRectMake(scrollView.contentOffset.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
}

- (void)finishedLoading {
    if (state == PullToRefreshViewStateLoading)
    {
        [UIView animateWithDuration:0.3f animations:^
        {
            [self setState:PullToRefreshViewStateNormal];
        }];
    }

//    [(AppDelegate *) [[UIApplication sharedApplication] delegate] showMenu];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[scrollView removeObserver:self forKeyPath:@"contentOffset"];
	scrollView = nil;
//    [super dealloc];
}

@end
