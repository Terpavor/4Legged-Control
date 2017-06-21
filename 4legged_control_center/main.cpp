#include <QApplication>

// for console window
#if defined(QT_DEBUG) && defined(Q_OS_WIN)
	#include <windows.h>
	#include <stdio.h>
#endif

#include "mainwindow.h"

int main(int argc, char *argv[])
{
	// create console window
#if defined(QT_DEBUG) && defined(Q_OS_WIN)
	FreeConsole();
	AllocConsole();
	AttachConsole(GetCurrentProcessId());
	freopen("CON", "w", stdout);
	freopen("CON", "w", stderr);
	freopen("CON", "r", stdin);
#endif


	QApplication a(argc, argv);

	MainWindow w;
	w.show();

	return a.exec();
}
