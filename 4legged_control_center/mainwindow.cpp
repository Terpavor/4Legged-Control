#include <cassert>

#include <QSettings>
#include <QtCore>
#include <QFileInfo>

#include <VLCQtCore/Common.h>
#include <VLCQtCore/Instance.h>
#include <VLCQtCore/Media.h>
#include <VLCQtCore/MediaPlayer.h>
#include <VLCQtCore/Audio.h>
#include <VLCQtCore/Enums.h>
#include <VLCQtCore/Error.h>
#include <VLCQtCore/Stats.h>

#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "settings.h"


MainWindow::MainWindow(QWidget *parent)
	: QMainWindow(parent)
	, ui(new Ui::MainWindow)
	, kb(this)
	, client("192.168.1.128", 33333)
{
	QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, QApplication::applicationDirPath());
	loadSettings();
	// settings dialog window
	settings = new Settings;

	ui->setupUi(this);
	repairUi();
	showBlankTelemetry();
	// not connected, 0 packets sent, 0 packets received
	updateStatusBarTcp(false, 0, 0);

	initKeyboardControl();
	initVlc();
	initConnectButton();
	initSaving();
	connectAll();

	// emit first log string
	emit printLog(constructLogEntry("Control Center", "INFO", "Program started"));

	//startTimer(50);     // ...-millisecond timer
}


void MainWindow::initKeyboardControl()
{
	kb.setButtons(
		QVector<QPushButton*>
		{
			ui->pushButton_Forward,
			ui->pushButton_RotateLeft,
			ui->pushButton_Backward,
			ui->pushButton_RotateRight,
			ui->pushButton_Left,
			ui->pushButton_Right
		}
	);
	kb.setFrequency(20); // Hz
	kb.start();
}
void MainWindow::initVlc()
{
	QStringList vlc_args;
	vlc_args << VlcCommon::args()
			 << "--network-caching=100"	// in ms. too low -> stream crashes, too big -> unacceptable lag
			 ;

	_instance	= new VlcInstance(vlc_args, this);
	_player		= new VlcMediaPlayer(_instance);
	_player->setVideoWidget(ui->widget_Video);

	ui->widget_Video->setMediaPlayer(_player);

	QString url = "rtsp://" + client.getAddress() + ':' + QString::number(rtsp_port) + "/unicast";
	qDebug() << url;
	// test url:  "rtsp://mpv.cdn3.bigCDN.com:554/bigCDN/_definst_/mp4:bigbuckbunnyiphone_400.mp4";

	_media = new VlcMedia(url, _instance);

	// "open stream" pressed -> _player->open(_media);
	connect(ui->pushButton_OpenStream, &QPushButton::clicked,
			[this]{ _player->open(_media); } );

	// error occured -> update status bar
	connect(_player,	&VlcMediaPlayer::error,
			this,		&MainWindow::updateStatusBarVlc );
	// video state changed -> update status bar
	connect(_player,	&VlcMediaPlayer::stateChanged,
			this,		&MainWindow::updateStatusBarVlc );
}
void MainWindow::initConnectButton()
{
	// off = disconnected
	QState *off = new QState();
	off->assignProperty(ui->pushButton_Connect, "text", "Connect");
	off->setObjectName("off");

	// on = connected
	QState *on = new QState();
	on->setObjectName("on");
	on->assignProperty(ui->pushButton_Connect, "text", "Disconnect");

	connect(off,	 &QState::exited, // off->on, call connectToServer
			&client, &TcpClient::connectToServer);
	connect(off,	 &QState::exited, // enable "STOP" button by lambda
			[this]{ ui->pushButton_STOP->setEnabled(true); });

	connect(on,		 &QState::exited, // on->off, call disconnectFromServer
			&client, &TcpClient::disconnectFromServer);
	connect(on,		 &QState::exited, // disable "STOP" button by lambda
			[this]{ ui->pushButton_STOP->setEnabled(false); });

	off->addTransition(ui->pushButton_Connect, &QPushButton::clicked, on);
	on ->addTransition (ui->pushButton_Connect, &QPushButton::clicked, off);

	connect_button_machine.addState(off);
	connect_button_machine.addState(on);

	connect_button_machine.setInitialState(off);
	connect_button_machine.start();
}
void MainWindow::initSaving()
{
	if(save_log)
	{
		log_file.setFileName(log_path
							 + '/'
							 + QDateTime::currentDateTime().toString("dd-MM-yyyy hh-mm-ss")
							 + ".log");
		log_file.open(QIODevice::WriteOnly | QIODevice::Text);

		log_file_stream.setDevice(&log_file);

		// some log printed in this program -> write it to log file
		connect(this,	&MainWindow::printLog,
				this,	&MainWindow::logToFile);
	}
	if(save_telemetry)
	{
		telemetry_file.setFileName(telemetry_path
							 + '/'
							 + QDateTime::currentDateTime().toString("dd-MM-yyyy hh-mm-ss")
							 + ".tsv");
		telemetry_file.open(QIODevice::WriteOnly | QIODevice::Text);

		telemetry_file_stream.setDevice(&telemetry_file);
	}
	if(save_video) // must be before VlcMediaPlayer::open()
	{
		_media->record(QDateTime::currentDateTime().toString("dd-MM-yyyy hh-mm-ss"),
					   QApplication::applicationDirPath(),
					   Vlc::Mux::MP4,
					   true);
	}
}
void MainWindow::connectAll()
{
	// connecting other signals->slots

	// tcp client state changed -> update status bar
	connect(&client,				&TcpClient::updateClientState,
			 this,					&MainWindow::updateStatusBarTcp);

	// some log printed in this program -> append string to log widget
	connect(this,					&MainWindow::printLog,
			ui->textEdit_Log,		&QTextEdit::insertPlainText);

	// new log string received from robot -> append string to log widget
	connect(&client,				&TcpClient::receivedLogPacket,
			ui->textEdit_Log,		&QTextEdit::append);

	// telemetry packet received -> update all telemetry labels
	connect(&client,				&TcpClient::receivedTelemetryPacket,
			 this,					&MainWindow::updateTelemetry);

	// connection lost -> show dummies again
	connect(&client,				&TcpClient::disconnected,
			 this,					&MainWindow::showBlankTelemetry);

	// "Settings" pressed in menu -> open menu dialog
	connect(ui->actionSettings,		&QAction::triggered,
			settings,				&Settings::open);

	// "start stream" pressed -> send command "streaming start"
	// to run v4l2rtspserver on onboard computer
	connect(ui->pushButton_StartStream, &QPushButton::clicked,
			[this]{ client.sendString("streaming start"); } );
}




void MainWindow::loadSettings()
{
	QSettings settings("config.ini", QSettings::IniFormat);

	qDebug() << QFileInfo(settings.fileName()).absolutePath() + "/";


	save_log =
			settings.value("file/save_log",
						   false).toBool();
	log_path =
			settings.value("file/log_path",
						   QApplication::applicationDirPath()).toString();
	save_telemetry =
			settings.value("file/save_telemetry",
						   true).toBool();
	telemetry_path =
			settings.value("file/telemetry_path",
						   QApplication::applicationDirPath()).toString();
	save_video =
			settings.value("file/save_video",
						   false).toBool();
	video_path =
			settings.value("file/video_path",
						   QApplication::applicationDirPath()).toString();
	client.setAddress(
			settings.value("connection/server_ip",
						   client.getAddress()).toString());
	client.setPortNumber(
			settings.value("connection/server_tcp_port",
						   client.getPortNumber()).toInt());
	rtsp_port =
			settings.value("connection/server_rtsp_port",
						   client.getPortNumber()).toInt();
}

void MainWindow::saveSettings()
{
	QSettings settings("config.ini", QSettings::IniFormat);

	qDebug() << QFileInfo(settings.fileName()).absolutePath() + "/";

	qDebug() << settings.status();

	settings.setValue("file/save_log",			save_log);
	settings.setValue("file/log_path",			log_path);
	settings.setValue("file/save_telemetry",	save_telemetry);
	settings.setValue("file/telemetry_path",	telemetry_path);
	settings.setValue("file/save_video",		save_video);
	settings.setValue("file/video_path",		video_path);
	settings.setValue("connection/server_ip",			client.getAddress());
	settings.setValue("connection/server_tcp_port",		client.getPortNumber());
	settings.setValue("connection/server_rtsp_port",	rtsp_port);
}

void MainWindow::updateTelemetry(TelemetryPacket t)
{
	QLabel *label_val;

	for(quint8 i = 0; i < TelemetryPacket::servo_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Angles%1").arg(i+1) );
		assert(label_val);
		label_val->setText( QString("%1°").arg(t.servo_position[i], 0, 'f', 1) );
	}
	for(quint8 i = 0; i < TelemetryPacket::battery_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Bat%1Volt").arg(i+1) );
		assert(label_val);
		label_val->setText( QString("%1 V").arg(t.battery_voltage[i], 0, 'f', 2) );

		label_val = this->findChild<QLabel*>( QString("label_Battery%1").arg(i+1) );
		assert(label_val);
		QString tmp = QString("🔋%1% ").arg(t.battery_voltage[i]*100.f/11.3f, 2, 'd', 0);
		quint8 j;
		for(j = 0; j < 13;  j++)		tmp+=QStringLiteral("⬛");
		for(     ; j < 14; j++)		tmp+=QStringLiteral("⬜");
		label_val->setText(tmp);
	}
	for(quint8 i = 0; i < TelemetryPacket::vector_size; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Accel%1").arg(i+1) );
		assert(label_val);
		label_val->setText( QString("%1 m/s<sup>2</sup>").arg(t.acceleration[i], 0, 'f', 2) );
	}
	for(quint8 i = 0; i < TelemetryPacket::vector_size; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Orient%1").arg(i+1) );
		assert(label_val);
		label_val->setText( QString("%1°").arg(t.orientation[i], 0, 'f', 2) );
	}
	for(quint8 i = 0; i < TelemetryPacket::leg_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Contact%1").arg(i+1) );
		assert(label_val);
		if(t.ground_contact[i])
			label_val->setText("<font color=#00FF55>●</font>"); // green circle
		else
			label_val->setText("<font color=#E51E1E>●</font>"); // red circle
	}


	// dummies

	label_val = this->findChild<QLabel*>( QString("labelVal_MotionState") );
	assert(label_val);
	label_val->setText( "Standing" );

	label_val = this->findChild<QLabel*>( QString("labelVal_CpuTemp") );
	assert(label_val);
	label_val->setText( QString("%1 ℃").arg(45.2, 0, 'f', 1) );

	label_val = this->findChild<QLabel*>( QString("labelVal_StatStab") );
	assert(label_val);
	label_val->setText( "~" );

	label_val = this->findChild<QLabel*>( QString("labelVal_DynStab") );
	assert(label_val);
	label_val->setText( "~" );

	if(save_telemetry)
	{
		telemetry_file_stream << t;
	}
}

void MainWindow::showBlankTelemetry()
{
	QLabel *label_val;

	for(quint8 i = 0; i < TelemetryPacket::servo_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Angles%1").arg(i+1) );
		assert(label_val);
		label_val->setText( "? °" );
	}
	for(quint8 i = 0; i < TelemetryPacket::battery_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Bat%1Volt").arg(i+1) );
		assert(label_val);
		label_val->setText( "? V" );

		label_val = this->findChild<QLabel*>( QString("label_Battery%1").arg(i+1) );
		assert(label_val);
		QString tmp = QStringLiteral("🔋??% ");
		for(quint8 j = 0; j < 14; j++)
			tmp+=QStringLiteral("⬜");
		label_val->setText(tmp);
	}
	for(quint8 i = 0; i < TelemetryPacket::vector_size; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Accel%1").arg(i+1) );
		assert(label_val);
		label_val->setText( "? m/s<sup>2</sup>" );
	}
	for(quint8 i = 0; i < TelemetryPacket::vector_size; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Orient%1").arg(i+1) );
		assert(label_val);
		label_val->setText( "? °" );
	}
	for(quint8 i = 0; i < TelemetryPacket::leg_count; i++)	{
		label_val = this->findChild<QLabel*>( QString("labelVal_Contact%1").arg(i+1) );
		assert(label_val);
		label_val->setText( "?" );
	}

	label_val = this->findChild<QLabel*>( QString("labelVal_MotionState") );
	assert(label_val);
	label_val->setText( "Unknown" );

	label_val = this->findChild<QLabel*>( QString("labelVal_CpuTemp") );
	assert(label_val);
	label_val->setText( "? ℃" );

	label_val = this->findChild<QLabel*>( QString("labelVal_StatStab") );
	assert(label_val);
	label_val->setText( "?" );

	label_val = this->findChild<QLabel*>( QString("labelVal_DynStab") );
	assert(label_val);
	label_val->setText( "?" );

}

void MainWindow::logToFile(const QString &str)
{
	log_file_stream << str;
}


void MainWindow::updateStatusBarTcp(bool is_connected, quint16 packets_sent, quint16 packets_received)
{
	ui->label_StatusBar1->setText( is_connected ? "connected" : "not connected" );
	ui->label_StatusBar2->setText( QString("%1 packets sent").arg(packets_sent, 4) );
	ui->label_StatusBar3->setText( QString("%2 packets received").arg(packets_received, 4) );
	//ui->statusBar->showMessage((is_connected ? "" : "not") + QString(" connected | %1 packets sent | %2 packets received").arg(packets_sent).arg(packets_received) );
}

void MainWindow::updateStatusBarVlc()
{
	// strings array for Vlc::State enum
	const QVector<QString> vlc_state = {
	  "idle", "opening", "buffering", "playing",
	  "paused", "stopped", "ended", "error"
	};

	QString err = VlcError::errmsg();

	ui->label_StatusBar4->setText(
		"[video] state: " + vlc_state.at(_player->state())
		+ (err.isEmpty() ? "" : (", error: " + err)) );
}


void MainWindow::repairUi()
{
	// Some magic constants for splitter.
	// Splitters stretching somehow broken in Qt... I can't set correct size by QtDesigner
	ui->mainLeftV->setSizes({25, 125});
}
// Some workaround, I can't reliably delegate focus to "KeyboardArrowsInput kb"
void MainWindow::keyPressEvent(QKeyEvent *e)
{
	kb.keyPressEvent(e);
}
void MainWindow::keyReleaseEvent(QKeyEvent *e)
{
	kb.keyReleaseEvent(e);
}

MainWindow::~MainWindow()
{
	_player->stop(); // ?
	delete _player;
	delete _media;
	delete _instance;
	delete ui;
}

