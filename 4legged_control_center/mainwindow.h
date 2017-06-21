#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QDateTime>
#include "QPushButton"
#include "QStateMachine"
#include "QLabel"

#include "tcp_client.h"
#include "simple_robot_protocol.h"
#include "keyboard_arrows_input.h"

#include "settings.h"


class VlcInstance;
class VlcMedia;
class VlcMediaPlayer;


namespace Ui
{
	class MainWindow;
}

inline QString constructLogEntry(const QString &sender, const QString &level, const QString &text)
{
	return QDateTime::currentDateTime().toString("dd.MM.yyyy hh:mm:ss.zzz")
			+ " | " + sender
			+ " | " + level
			+ " | " + text + '\n';
}


class MainWindow : public QMainWindow
{
	Q_OBJECT

	QStateMachine connect_button_machine;

	Ui::MainWindow *ui;
	Settings *settings;

	KeyboardArrowsInput kb;

	TcpClient		client;

	VlcInstance	   *_instance;
	VlcMedia	   *_media;
	VlcMediaPlayer *_player;

	const QString settings_filename = QApplication::applicationDirPath().left(1) + ":/settings.ini";

	bool save_log;
	QString log_path;
	QFile log_file;
	QTextStream log_file_stream;

	bool save_telemetry;
	QString telemetry_path;
	QFile telemetry_file;
	QTextStream telemetry_file_stream;

	bool save_video;
	QString video_path;

	quint16 rtsp_port;


	void initKeyboardControl();
	void initVlc();
	void initConnectButton();
	void connectAll();
	void initSaving();


	void loadSettings();
	void saveSettings();

	void keyPressEvent(QKeyEvent *);
	void keyReleaseEvent(QKeyEvent *);

	void repairUi();

private slots:
	void updateTelemetry(TelemetryPacket);
	void showBlankTelemetry();
	void updateStatusBarTcp(bool, quint16, quint16);
	void updateStatusBarVlc();
	void logToFile(const QString &);


public:
	explicit MainWindow(QWidget *parent = 0);
	~MainWindow();

signals:
	void printLog(const QString &);

};

#endif // MAINWINDOW_H
