/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "config.h"
#import "UIScriptController.h"

#import "PlatformWebView.h"
#import "StringFunctions.h"
#import "TestController.h"
#import "TestRunnerWKWebView.h"
#import "UIScriptContext.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WKWebViewPrivate.h>

namespace WTR {

void UIScriptController::setViewScale(double scale)
{
    TestController::singleton().mainWebView()->platformView()._viewScale = scale;
}

void UIScriptController::setMinimumEffectiveWidth(double effectiveWidth)
{
    TestController::singleton().mainWebView()->platformView()._minimumEffectiveDeviceWidth = effectiveWidth;
}

void UIScriptController::setAllowsViewportShrinkToFit(bool allows)
{
#if PLATFORM(IOS_FAMILY)
    TestController::singleton().mainWebView()->platformView()._allowsViewportShrinkToFit = allows;
#else
    UNUSED_PARAM(allows);
#endif
}

void UIScriptController::resignFirstResponder()
{
    [TestController::singleton().mainWebView()->platformView() resignFirstResponder];
}

void UIScriptController::doAsyncTask(JSValueRef callback)
{
    unsigned callbackID = m_context->prepareForAsyncTask(callback, CallbackTypeNonPersistent);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!m_context)
            return;
        m_context->asyncTaskComplete(callbackID);
    });
}

void UIScriptController::setShareSheetCompletesImmediatelyWithResolution(bool resolved)
{
    TestRunnerWKWebView *webView = TestController::singleton().mainWebView()->platformView();
    [webView _setShareSheetCompletesImmediatelyWithResolutionForTesting:resolved];
}

void UIScriptController::removeViewFromWindow(JSValueRef callback)
{
    // FIXME: On iOS, we never invoke the completion callback that's passed in. Fixing this causes the layout
    // test pageoverlay/overlay-remove-reinsert-view.html to start failing consistently on iOS. It seems like
    // this warrants some more investigation.
#if PLATFORM(MAC)
    unsigned callbackID = m_context->prepareForAsyncTask(callback, CallbackTypeNonPersistent);
#else
    UNUSED_PARAM(callback);
#endif

    auto* mainWebView = TestController::singleton().mainWebView();
    mainWebView->removeFromWindow();

#if PLATFORM(MAC)
    [mainWebView->platformView() _doAfterNextPresentationUpdate:^{
        if (!m_context)
            return;
        m_context->asyncTaskComplete(callbackID);
    }];
#endif // PLATFORM(MAC)
}

void UIScriptController::addViewToWindow(JSValueRef callback)
{
#if PLATFORM(MAC)
    unsigned callbackID = m_context->prepareForAsyncTask(callback, CallbackTypeNonPersistent);
#else
    UNUSED_PARAM(callback);
#endif

    auto* mainWebView = TestController::singleton().mainWebView();
    mainWebView->addToWindow();

#if PLATFORM(MAC)
    [mainWebView->platformView() _doAfterNextPresentationUpdate:^{
        if (!m_context)
            return;
        m_context->asyncTaskComplete(callbackID);
    }];
#endif // PLATFORM(MAC)
}

void UIScriptController::overridePreference(JSStringRef preferenceRef, JSStringRef valueRef)
{
    TestRunnerWKWebView *webView = TestController::singleton().mainWebView()->platformView();
    WKPreferences *preferences = webView.configuration.preferences;

    String preference = toWTFString(toWK(preferenceRef));
    String value = toWTFString(toWK(valueRef));
    if (preference == "WebKitMinimumFontSize")
        preferences.minimumFontSize = value.toDouble();
}

void UIScriptController::findString(JSStringRef string, unsigned long options, unsigned long maxCount)
{
    TestRunnerWKWebView *webView = TestController::singleton().mainWebView()->platformView();
    [webView _findString:toWTFString(toWK(string)) options:options maxCount:maxCount];
}

JSObjectRef UIScriptController::contentsOfUserInterfaceItem(JSStringRef interfaceItem) const
{
    TestRunnerWKWebView *webView = TestController::singleton().mainWebView()->platformView();
    NSDictionary *contentDictionary = [webView _contentsOfUserInterfaceItem:toWTFString(toWK(interfaceItem))];
    return JSValueToObject(m_context->jsContext(), [JSValue valueWithObject:contentDictionary inContext:[JSContext contextWithJSGlobalContextRef:m_context->jsContext()]].JSValueRef, nullptr);
}

void UIScriptController::setDefaultCalendarType(JSStringRef calendarIdentifier)
{
    TestController::singleton().setDefaultCalendarType((__bridge NSString *)adoptCF(JSStringCopyCFString(kCFAllocatorDefault, calendarIdentifier)).get());
}

JSRetainPtr<JSStringRef> UIScriptController::lastUndoLabel() const
{
    return adopt(JSStringCreateWithCFString((__bridge CFStringRef)platformUndoManager().undoActionName));
}

JSRetainPtr<JSStringRef> UIScriptController::firstRedoLabel() const
{
    return adopt(JSStringCreateWithCFString((__bridge CFStringRef)platformUndoManager().redoActionName));
}

NSUndoManager *UIScriptController::platformUndoManager() const
{
    return platformContentView().undoManager;
}

} // namespace WTR
