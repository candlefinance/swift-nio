//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This is a companion to System.swift that provides only Linux specials: either things that exist
// only on Linux, or things that have Linux-specific extensions.

#if os(Linux) || os(Android)
import CandleCNIOLinux
internal enum TimerFd {
    internal static let TFD_CLOEXEC = CandleCNIOLinux.TFD_CLOEXEC
    internal static let TFD_NONBLOCK = CandleCNIOLinux.TFD_NONBLOCK

    @inline(never)
    internal static func timerfd_settime(
        fd: CInt,
        flags: CInt,
        newValue: UnsafePointer<itimerspec>,
        oldValue: UnsafeMutablePointer<itimerspec>?
    ) throws {
        _ = try syscall(blocking: false) {
            CandleCNIOLinux.timerfd_settime(fd, flags, newValue, oldValue)
        }
    }

    @inline(never)
    internal static func timerfd_create(clockId: CInt, flags: CInt) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.timerfd_create(clockId, flags)
        }.result
    }
}
internal enum EventFd {
    internal static let EFD_CLOEXEC = CandleCNIOLinux.EFD_CLOEXEC
    internal static let EFD_NONBLOCK = CandleCNIOLinux.EFD_NONBLOCK
    internal typealias eventfd_t = CandleCNIOLinux.eventfd_t

    @inline(never)
    internal static func eventfd_write(fd: CInt, value: UInt64) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.eventfd_write(fd, value)
        }.result
    }

    @inline(never)
    internal static func eventfd_read(fd: CInt, value: UnsafeMutablePointer<UInt64>) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.eventfd_read(fd, value)
        }.result
    }

    @inline(never)
    internal static func eventfd(initval: CUnsignedInt, flags: CInt) throws -> CInt {
        try syscall(blocking: false) {
            // Note: Please do _not_ remove the `numericCast`, this is to allow compilation in Ubuntu 14.04 and
            // other Linux distros which ship a glibc from before this commit:
            // https://sourceware.org/git/?p=glibc.git;a=commitdiff;h=69eb9a183c19e8739065e430758e4d3a2c5e4f1a
            // which changes the first argument from `CInt` to `CUnsignedInt` (from Sat, 20 Sep 2014).
            CandleCNIOLinux.eventfd(numericCast(initval), flags)
        }.result
    }
}
internal enum Epoll {
    internal typealias epoll_event = CandleCNIOLinux.epoll_event
    internal static let EPOLL_CTL_ADD: CInt = numericCast(CandleCNIOLinux.EPOLL_CTL_ADD)
    internal static let EPOLL_CTL_MOD: CInt = numericCast(CandleCNIOLinux.EPOLL_CTL_MOD)
    internal static let EPOLL_CTL_DEL: CInt = numericCast(CandleCNIOLinux.EPOLL_CTL_DEL)

    #if canImport(Android) || canImport(Musl)
    internal static let EPOLLIN: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLIN)
    internal static let EPOLLOUT: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLOUT)
    internal static let EPOLLERR: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLERR)
    internal static let EPOLLRDHUP: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLRDHUP)
    internal static let EPOLLHUP: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLHUP)
    #if canImport(Android)
    internal static let EPOLLET: CUnsignedInt = 2_147_483_648  // C macro not imported by ClangImporter
    #else
    internal static let EPOLLET: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLET)
    #endif
    #elseif os(Android)
    internal static let EPOLLIN: CUnsignedInt = 1  //numericCast(CandleCNIOLinux.EPOLLIN)
    internal static let EPOLLOUT: CUnsignedInt = 4  //numericCast(CandleCNIOLinux.EPOLLOUT)
    internal static let EPOLLERR: CUnsignedInt = 8  // numericCast(CandleCNIOLinux.EPOLLERR)
    internal static let EPOLLRDHUP: CUnsignedInt = 8192  //numericCast(CandleCNIOLinux.EPOLLRDHUP)
    internal static let EPOLLHUP: CUnsignedInt = 16  //numericCast(CandleCNIOLinux.EPOLLHUP)
    internal static let EPOLLET: CUnsignedInt = 2_147_483_648  //numericCast(CandleCNIOLinux.EPOLLET)
    #else
    internal static let EPOLLIN: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLIN.rawValue)
    internal static let EPOLLOUT: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLOUT.rawValue)
    internal static let EPOLLERR: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLERR.rawValue)
    internal static let EPOLLRDHUP: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLRDHUP.rawValue)
    internal static let EPOLLHUP: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLHUP.rawValue)
    internal static let EPOLLET: CUnsignedInt = numericCast(CandleCNIOLinux.EPOLLET.rawValue)
    #endif
    internal static let ENOENT: CUnsignedInt = numericCast(CandleCNIOLinux.ENOENT)

    @inline(never)
    internal static func epoll_create(size: CInt) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.epoll_create(size)
        }.result
    }

    @inline(never)
    @discardableResult
    internal static func epoll_ctl(
        epfd: CInt,
        op: CInt,
        fd: CInt,
        event: UnsafeMutablePointer<epoll_event>
    ) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.epoll_ctl(epfd, op, fd, event)
        }.result
    }

    @inline(never)
    internal static func epoll_wait(
        epfd: CInt,
        events: UnsafeMutablePointer<epoll_event>,
        maxevents: CInt,
        timeout: CInt
    ) throws -> CInt {
        try syscall(blocking: false) {
            CandleCNIOLinux.epoll_wait(epfd, events, maxevents, timeout)
        }.result
    }
}

internal enum Linux {
    #if os(Android)
    #if compiler(>=6.0)
    static let SOCK_CLOEXEC = Android.SOCK_CLOEXEC
    static let SOCK_NONBLOCK = Android.SOCK_NONBLOCK
    #else
    static let SOCK_CLOEXEC = Glibc.SOCK_CLOEXEC
    static let SOCK_NONBLOCK = Glibc.SOCK_NONBLOCK
    #endif
    #elseif canImport(Musl)
    static let SOCK_CLOEXEC = Musl.SOCK_CLOEXEC
    static let SOCK_NONBLOCK = Musl.SOCK_NONBLOCK
    #else
    static let SOCK_CLOEXEC = CInt(bitPattern: Glibc.SOCK_CLOEXEC.rawValue)
    static let SOCK_NONBLOCK = CInt(bitPattern: Glibc.SOCK_NONBLOCK.rawValue)
    #endif
    @inline(never)
    internal static func accept4(
        descriptor: CInt,
        addr: UnsafeMutablePointer<sockaddr>?,
        len: UnsafeMutablePointer<socklen_t>?,
        flags: CInt
    ) throws -> CInt? {
        guard
            case let .processed(fd) = try syscall(
                blocking: true,
                {
                    CandleCNIOLinux.CNIOLinux_accept4(descriptor, addr, len, flags)
                }
            )
        else {
            return nil
        }
        return fd
    }
}
#endif
