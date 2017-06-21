#include <cassert>

#include <QDebug>

#include "keyboard_arrows_input.h"


KeyboardArrowsInput::KeyboardArrowsInput(QWidget *parent)
	: QWidget(parent) {}

KeyboardArrowsInput::~KeyboardArrowsInput() {}

void KeyboardArrowsInput::setFrequency(quint16 frequency)
{
	assert(frequency > 10 && "Frequency must be greater than 10 to correctly process QPushButton::isDown()");
	period_in_ms = 1000/frequency;
}

void KeyboardArrowsInput::setButtons(QVector<QPushButton*> new_buttons)
{
	assert(new_buttons.count() == button_count);

	for(quint8 i = 0; i < button_count; i++)
		buttons[i] = new_buttons[i];
}

void KeyboardArrowsInput::start()
{
	// see keyboard processing f-n timerEvent()
	keyboard_timer.start(period_in_ms, this);
}
void KeyboardArrowsInput::stop()
{
	keyboard_timer.stop();
}

void KeyboardArrowsInput::keyPressEvent(QKeyEvent *e)
{
	if(e->isAutoRepeat())
		return;
	keys_pressed += (Qt::Key)e->key();
	// to handle shift key:
	//... | (e->modifiers() & Qt::ShiftModifier);
}

void KeyboardArrowsInput::keyReleaseEvent(QKeyEvent *e)
{
	if(e->isAutoRepeat())
		return;
	keys_pressed -= (Qt::Key)e->key();
	// to handle shift key:
	//... | Qt::ShiftModifier;
}

void KeyboardArrowsInput::timerEvent(QTimerEvent *e)
{
	assert(e->timerId() == keyboard_timer.timerId());

	foreach(Qt::Key k, keys_pressed)
	{
		switch(k) {

		//case Qt::Key_8 :
		case Qt::Key_Up :
		case Qt::Key_W :	buttons[b_forward]->animateClick();			break;

		//case Qt::Key_4 :
		case Qt::Key_Left :
		case Qt::Key_A :	buttons[b_rotate_left]->animateClick();		break;

		//case Qt::Key_2 :
		case Qt::Key_Down :
		case Qt::Key_S :	buttons[b_backward]->animateClick();		break;

		//case Qt::Key_6 :
		case Qt::Key_Right :
		case Qt::Key_D :	buttons[b_rotate_right]->animateClick();	break;

		//case Qt::Key_7 :
		case Qt::Key_Q :	buttons[b_left]->animateClick();			break;

		//case Qt::Key_9 :
		case Qt::Key_E :	buttons[b_right]->animateClick();			break;

		default :
			break;
		}
	}



	/*
	bool state_array[6] ={0};

	for(uint i = 0; i< button_count; i++)
	{
		state_array[i] = buttons[i]->isDown();
	}

	QDebug debug = qDebug();
	for(uint i = 0 ; i < button_count; i++)
		debug<<int(state_array[i]);


	*/
}
