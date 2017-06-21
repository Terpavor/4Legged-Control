#-------------------------------------------------
#
# Project created by QtCreator 2017-06-12T12:49:48
#
#-------------------------------------------------

QT			+=	core		\
				gui			\
				network		\ # TCP socket
				widgets

CONFIG		+=  c++11

CFLAGS		+= -Wall		\
			   -Wpedantic	\
			   -O3

TARGET		=	ui_robot_test
TEMPLATE	=	app

# for VLC
LIBS		+=	-lVLCQtCore \
				-lVLCQtWidgets
INCLUDEPATH +=										\
	O:/Documents/Qt/VLC-Qt_1.1.0_win32_mingw/include
LIBS		+=										\
	-LO:/Documents/Qt/VLC-Qt_1.1.0_win32_mingw/lib	\
					-lVLCQtCore						\
					-lVLCQtWidgets
# /for VLC

DEFINES		+= QT_DEPRECATED_WARNINGS

SOURCES		+= main.cpp			\
	mainwindow.cpp				\
	simple_robot_protocol.cpp	\
	tcp_client.cpp				\
	keyboard_arrows_input.cpp	\
    settings.cpp

HEADERS		+=					\
	mainwindow.h				\
	simple_robot_protocol.h		\
    tcp_client.h \
    keyboard_arrows_input.h \
    settings.h

FORMS		+=					\
	mainwindow.ui				\
    settings.ui


VERSION = 0.1.0

QMAKE_TARGET_DESCRIPTION =		\
	"Control system for four-legged robot, created in ITMO University"

QMAKE_TARGET_PRODUCT = "4Legged Control"

# icon
win32:RC_ICONS += app.ico
