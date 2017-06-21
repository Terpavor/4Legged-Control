#include <QSettings>
#include <QDebug>
#include <QMessageBox>
#include <QProcess>

#include "settings.h"
#include "ui_settings.h"

Settings::Settings(QWidget *parent) :
	QDialog(parent),
	ui(new Ui::Settings)
{
	ui->setupUi(this);


	QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, QApplication::applicationDirPath());
	loadSettings();

	// click on browse... -> select folder and fill lineEdit(lambda)
	// log
	connect(ui->pushButton_LogBrowse, &QPushButton::clicked,
			[this]{
					ui->lineEdit_LogPath->setText
							(
								QFileDialog::getExistingDirectory(0,
																  ("Select Output Folder"),
																  QApplication::applicationDirPath())
							);
				  });
	// telemetry
	connect(ui->pushButton_TelemetryBrowse, &QPushButton::clicked,
			[this]{
					ui->lineEdit_TelemetryPath->setText
							(
								QFileDialog::getExistingDirectory(0,
																  ("Select Output Folder"),
																  QApplication::applicationDirPath())
							);
				  });
	// video
	connect(ui->pushButton_VideoBrowse, &QPushButton::clicked,
			[this]{
					ui->lineEdit_VideoPath->setText
							(
								QFileDialog::getExistingDirectory(0,
																  ("Select Output Folder"),
																  QApplication::applicationDirPath())
							);
				  });

	// click on accepted -> save to .ini and exit
	connect(ui->buttonBox,	&QDialogButtonBox::accepted,
			this,			&Settings::askAndExit);
	// click on rejected -> exit
	connect(ui->buttonBox,	&QDialogButtonBox::rejected,
			this,			&Settings::hide);
}
void Settings::loadSettings()
{
	QSettings settings("config.ini", QSettings::IniFormat);

	ui->groupBox_Log->setChecked(
			settings.value("file/save_log",
						   false).toBool());
	ui->lineEdit_LogPath->setText(
			settings.value("file/log_path",
						   QApplication::applicationDirPath()).toString());
	ui->groupBox_Telemetry->setChecked(
			settings.value("file/save_telemetry",
						   true).toBool());
	ui->lineEdit_TelemetryPath->setText(
			settings.value("file/telemetry_path",
						   QApplication::applicationDirPath()).toString());
	ui->groupBox_Video->setChecked(
			settings.value("file/save_video",
						   false).toBool());
	ui->lineEdit_VideoPath->setText(
			settings.value("file/video_path",
						   QApplication::applicationDirPath()).toString());
	ui->lineEdit_IP->setText(
			settings.value("connection/server_ip",
						   "192.168.0.0").toString());
	ui->spinBox_Port->setValue(
			settings.value("connection/server_tcp_port",
						   0).toInt());
	ui->spinBox_VPort->setValue(
			settings.value("connection/server_rtsp_port",
						   0).toInt());
}
void Settings::saveSettings()
{
	QSettings settings("config.ini", QSettings::IniFormat);

	settings.setValue("file/save_log",			ui->groupBox_Log->isChecked());
	settings.setValue("file/log_path",			ui->lineEdit_LogPath->text());
	settings.setValue("file/save_telemetry",	ui->groupBox_Telemetry->isChecked());
	settings.setValue("file/telemetry_path",	ui->lineEdit_TelemetryPath->text());
	settings.setValue("file/save_video",		ui->groupBox_Video->isChecked());
	settings.setValue("file/video_path",		ui->lineEdit_VideoPath->text());
	settings.setValue("connection/server_ip",		 ui->lineEdit_IP->text());
	settings.setValue("connection/server_tcp_port",  ui->spinBox_Port->value());
	settings.setValue("connection/server_rtsp_port", ui->spinBox_VPort->value());

	settings.sync();
}

void Settings::askAndExit()
{
	QMessageBox msgBox;
	msgBox.setText("Changes will be applied after reset.\nReset now?(Yes - reset, No - continue)");
	msgBox.setStandardButtons( QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel );
	msgBox.setDefaultButton(QMessageBox::No);
	int ret = msgBox.exec();

	switch (ret) {
	case QMessageBox::Yes:
		saveSettings();
		QProcess::startDetached(QApplication::applicationFilePath());
		QCoreApplication::exit(12);
		break;

	case QMessageBox::No:
		saveSettings();
		this->hide();
		break;

	case QMessageBox::Cancel:
	default:
		break;
  }

}

Settings::~Settings()
{
	delete ui;
}
