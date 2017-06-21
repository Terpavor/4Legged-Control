#ifndef SETTINGS_H
#define SETTINGS_H

#include <QDialog>
#include <QFileDialog>
#include <QIntValidator>


namespace Ui {
class Settings;
}

class Settings : public QDialog
{
	Q_OBJECT

	Ui::Settings *ui;

	QFileDialog folder_dialog;


	void loadSettings();
	void saveSettings();

private slots:
	void askAndExit();


public:
	explicit Settings(QWidget *parent = 0);
	~Settings();
};

#endif // SETTINGS_H
