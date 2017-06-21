#ifndef KEYBOARD_ARROWS_INPUT_H
#define KEYBOARD_ARROWS_INPUT_H

#include <QWidget>
#include <QBasicTimer>
#include <QKeyEvent>
#include <QPushButton>
#include <QApplication>

class KeyboardArrowsInput : public QWidget // QWidget has all needed events
{
	Q_OBJECT

	enum { button_count = 6 };

	enum { // indexes for button pointers array
		b_forward,
		b_rotate_left,
		b_backward,
		b_rotate_right,
		b_left,
		b_right
	};

	QPushButton *buttons[button_count];

	QSet<Qt::Key>	keys_pressed;

	quint16 period_in_ms;
	QBasicTimer		keyboard_timer;


	void timerEvent(QTimerEvent *);


public:
	explicit KeyboardArrowsInput(QWidget *);
	~KeyboardArrowsInput();

	void setFrequency(quint16);
	void setButtons(QVector<QPushButton*>);
	void start();
	void stop();

	void keyPressEvent(QKeyEvent *);
	void keyReleaseEvent(QKeyEvent *);
};




#endif // KEYBOARD_ARROWS_INPUT_H
